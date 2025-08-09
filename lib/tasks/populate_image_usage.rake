namespace :dev do
  desc 'Populate dev database with test image references for testing image usage functionality'
  task populate_image_usage: :environment do
    return unless Rails.env.development?

    test_image = 'Encontrar-tus-ritmos-organizandote-mejor.webp'
    test_image_url = "https://kleer-images.s3.sa-east-1.amazonaws.com/#{test_image}"

    puts "Adding #{test_image} to various models for testing..."

    # Load all models to ensure ImageReference registrations are complete
    Rails.application.eager_load!

    # Article - add to cover and embed in body (description has length limit)
    if Article.exists?
      article = Article.first
      if article
        article.update!(
          cover: test_image_url,
          body: if article.body
                  "#{article.body} <img src='#{test_image_url}' alt='Test image'/>"
                else
                  "Article body with test image: <img src='#{test_image_url}' alt='Test image'/>"
                end
        )
        puts "✓ Updated Article ##{article.id} with test image"
      end
    else
      article = Article.create!(
        title: 'Test Article for Image Usage',
        body: "This is a test article for image usage testing. <img src='#{test_image_url}' alt='Test image'/>",
        cover: test_image_url,
        description: 'Test article for image usage',
        lang: 0, # es
        published: true
      )
      puts "✓ Created Article ##{article.id} with test image"
    end

    # EventType - add to cover and embed in description
    if EventType.exists?
      event_type = EventType.first
      if event_type
        event_type.update!(
          cover: test_image_url,
          description: 'Course with test image',
          program: if event_type.program
                     "#{event_type.program} Image: #{test_image_url}"
                   else
                     "Program content with image: #{test_image_url}"
                   end
        )
        puts "✓ Updated EventType ##{event_type.id} with test image"
      end
    else
      event_type = EventType.create!(
        name: 'Test Course for Image Usage',
        cover: test_image_url,
        description: 'Course with test image',
        program: "Program content with image: #{test_image_url}",
        lang: 0,
        duration_in_hours: 8,
        price: 100
      )
      puts "✓ Created EventType ##{event_type.id} with test image"
    end

    # News - add to img field (skip description - too short for URLs)
    if News.exists?
      news = News.first
      if news
        news.update!(img: test_image_url)
        puts "✓ Updated News ##{news.id} with test image in img field"
      end
    else
      news = News.create!(
        title: 'Test News for Image Usage',
        img: test_image_url,
        description: 'Test news item',
        lang: 0,
        event_date: Date.current
      )
      puts "✓ Created News ##{news.id} with test image in img field"
    end

    # Coupon - add to icon field
    if Coupon.exists?
      coupon = Coupon.first
      if coupon
        coupon.update!(icon: test_image_url)
        puts "✓ Updated Coupon ##{coupon.id} with test image"
      end
    else
      coupon = Coupon.create!(
        name: 'Test Coupon for Image Usage',
        code: 'TEST_IMAGE_USAGE',
        icon: test_image_url,
        percentage: 10,
        enabled: true
      )
      puts "✓ Created Coupon ##{coupon.id} with test image"
    end

    # Assessment with Questions, Answers, and QuestionGroups
    # Note: Only embedding images in longer text fields, not short descriptions
    assessment = Assessment.find_or_create_by(title: 'Test Assessment for Image Usage') do |a|
      a.description = 'Test assessment for image usage functionality'
    end

    puts "✓ Created Assessment ##{assessment.id} (no image embedding in short description)"

    # QuestionGroup - skip description embedding (likely short field)
    question_group = assessment.question_groups.find_or_create_by(name: 'Test Group') do |qg|
      qg.description = 'Test question group'
    end
    puts "✓ Created QuestionGroup ##{question_group.id} (no image embedding in short description)"

    # Question - skip description embedding (likely short field)
    question = assessment.questions.find_or_create_by(name: 'Test Question') do |q|
      q.description = 'Test question for image usage'
      q.question_group = question_group
    end
    puts "✓ Created Question ##{question.id} (no image embedding in short description)"

    # Answer - this might be longer text, so we can embed here
    answer = question.answers.find_or_create_by(position: 1) do |a|
      a.text = "Answer text with embedded image reference: #{test_image_url}"
    end
    puts "✓ Created Answer ##{answer.id} with embedded image URL"

    # Resource - add to cover fields
    if Resource.exists?
      resource = Resource.first
      if resource
        resource.update!(cover_es: test_image_url, cover_en: test_image_url)
        puts "✓ Updated Resource ##{resource.id} with test image"
      end
    else
      resource = Resource.create!(
        title: 'Test Resource for Image Usage',
        cover_es: test_image_url,
        cover_en: test_image_url,
        getit_es: "Spanish description with image: #{test_image_url}",
        getit_en: "English description with image: #{test_image_url}",
        lang: 0
      )
      puts "✓ Created Resource ##{resource.id} with test image"
    end

    # Service - add to brochure field
    if Service.exists?
      service = Service.first
      if service
        service.update!(brochure: test_image_url)
        puts "✓ Updated Service ##{service.id} with test image"
      end
    else
      service = Service.create!(
        name: 'Test Service for Image Usage',
        brochure: test_image_url,
        lang: 0
      )
      puts "✓ Created Service ##{service.id} with test image"
    end

    # Participant - add to photo_url
    if Participant.exists?
      participant = Participant.first
      if participant
        participant.update!(photo_url: test_image_url)
        puts "✓ Updated Participant ##{participant.id} with test image"
      end
    end

    puts
    puts '✅ Successfully populated dev database with test image references!'
    puts "You can now test the image usage page with: #{test_image}"
    puts "Visit: /admin/images/usage?bucket=image&key=#{test_image}"
    puts
    puts "Models updated with #{test_image}:"
    puts '- Article (cover + body) - URL field + long text'
    puts '- EventType (cover + program) - URL field + long text'
    puts '- News (img) - URL field only'
    puts '- Coupon (icon) - URL field only'
    puts '- Assessment/QuestionGroup/Question - no image (descriptions too short)'
    puts '- Answer (text) - embedded in longer text field'
    puts '- Resource (cover_es, cover_en, getit_es, getit_en) - URL + text fields'
    puts '- Service (brochure) - URL field only'
    puts '- Participant (photo_url) - URL field only [if exists]'
    puts ''
    puts 'Note: Image URLs are only embedded in longer text fields where practical.'
    puts 'Short description fields (160 chars) are not suitable for full image URLs.'
  end
end
