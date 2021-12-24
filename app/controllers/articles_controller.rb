class ArticlesController < ApplicationController
  before_action :set_article, only: [:show, :edit, :update, :destroy]

  # GET /articles
  def index
    @articles = Article.all
    respond_to do |format|
      format.html
      format.json { render json: @articles.order(created_at: :desc),
                    methods: [:abstract],
                    include: {trainers: {only: :name}} 
                  }
    end
  end

  # GET /articles/1
  def show
    respond_to do |format|
      format.html
      format.json { render json: @article, include: {trainers: {only: :name}} }
    end
  end
  
  # GET /articles/new
  def new
    @article = Article.new
  end

  # GET /articles/1/edit
  def edit
  end

  # POST /articles
  def create
    @article = Article.new(article_params)

    if @article.save
      redirect_to @article, notice: 'Article was successfully created.'
    else
      render :new
    end
  end

  # PATCH/PUT /articles/1
  def update
    if @article.update(article_params)
      redirect_to @article, notice: 'Article was successfully updated.'
    else
      render :edit
    end
  end

  # DELETE /articles/1
  def destroy
    @article.destroy
    redirect_to articles_url, notice: 'Article was successfully destroyed.'
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_article
      @article = Article.friendly.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def article_params
      params.require(:article).permit(:title, :slug, :body, :description, :published, :tabtitle, trainer_ids: [])
    end
end
