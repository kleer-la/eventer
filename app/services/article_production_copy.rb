# frozen_string_literal: true

require 'net/http'

# Copies an article from production into this environment, so QA looks like
# production when something is tested against it (kleer-la/eventer#216). It
# reads production's public API by slug and writes through ArticleWriteService,
# so the preview, the permissions and the savepoint are the usual ones. What
# the article points to — category, authors, recommendations — is matched here
# by name or slug; what this environment lacks is skipped and said, rather than
# failing the copy.
class ArticleProductionCopy
  FIELDS = %w[title tabtitle description body lang slug cover header industry noindex selected redirect_url].freeze

  class FetchError < StandardError; end

  def self.source = ENV['PRODUCTION_API_URL'].presence

  def initialize(ability:, slug:)
    @ability = ability
    @slug = slug.to_s
    @warnings = []
  end

  def call(confirm: false)
    unless self.class.source
      return { status: 'error', errors: ['Only on QA: copy_from_production needs PRODUCTION_API_URL'] }
    end

    data = fetch
    result = write(data, confirm:)
    %w[preview saved].include?(result[:status]) ? with_recommendations(result, data) : result
  rescue FetchError => e
    { status: 'error', errors: [e.message] }
  end

  private

  def url = "#{self.class.source.chomp('/')}/api/articles/#{ERB::Util.url_encode(@slug)}"

  def fetch
    response = Net::HTTP.get_response(URI(url))
    unless response.is_a?(Net::HTTPSuccess)
      raise FetchError, "Production answered #{response.code} for article #{@slug}"
    end

    JSON.parse(response.body)
  rescue JSON::ParserError, SocketError, Timeout::Error, SystemCallError => e
    raise FetchError, "Could not read article #{@slug} from production: #{e.message}"
  end

  def write(data, confirm:)
    ArticleWriteService.new(ability: @ability, record: Article.find_by(slug: @slug),
                            **data.slice(*FIELDS).symbolize_keys,
                            published: data['published'], category: category(data), trainers: trainers(data))
                       .call(confirm:)
  end

  def category(data)
    name = data['category_name']
    return name if name.blank? || Category.exists?(name:)

    @warnings << "Category #{name.inspect} does not exist here: the article is copied without one."
    nil
  end

  def trainers(data)
    names = Array(data['trainers']).pluck('name')
    found = Trainer.where(name: names).pluck(:name)
    missing = names - found
    @warnings << "Authors missing here, left out: #{missing.join(', ')}." if missing.any?
    found
  end

  def with_recommendations(result, data)
    links, missing = recommendations(data)
    relink(Article.find(result[:id]), links) if result[:status] == 'saved'
    result.merge(source: url, recommendations: { link: links.map(&:first), missing: },
                 warnings: Array(result[:warnings]) + @warnings)
  end

  # [[label, target, relevance_order]] for the recommendations found here, and
  # the labels of the ones that are not.
  def recommendations(data)
    found = []
    missing = []
    Array(data['recommended']).each do |rec|
      label = "#{rec['type']} #{rec['slug']}"
      target = target_for(rec)
      target ? found << [label, target, rec['relevance_order']] : missing << label
    end
    [found, missing]
  end

  def target_for(rec)
    model = rec['type'].to_s.camelize
    return unless RecommendationService::TARGET_TYPES.include?(model)

    klass = model.constantize
    klass.find_by(slug: rec['slug']) if klass.column_names.include?('slug')
  end

  # The recommendations become production's, as far as this environment has them.
  def relink(article, links)
    article.recommended_contents.destroy_all
    links.each do |_label, target, order|
      article.recommended_contents.create!(target:, relevance_order: order || RecommendationService::DEFAULT_RELEVANCE)
    end
  end
end
