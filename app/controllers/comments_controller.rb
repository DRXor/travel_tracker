class CommentsController < ApplicationController
  before_action :require_login
  before_action :set_trip
  before_action :set_comment, only: [:edit, :update, :destroy]

  def create
    @comment = @trip.comments.build(comment_params)
    @comment.user = current_user

    if @comment.save
      render_form(Comment.new)
    else
      render_form(@comment, status: :unprocessable_entity)
    end
  end

  def edit
  end

  def update
    if @comment.update(comment_params)
      redirect_to trip_path(@trip), status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @comment.destroy
    redirect_to trip_path(@trip), notice: "Комментарий удалён.", status: :see_other
  end

  private

  def set_trip
    @trip = current_user.accessible_trips.find(params[:trip_id])
  end

  # Менять и удалять можно только свои комментарии
  def set_comment
    @comment = @trip.comments.where(user: current_user).find(params[:id])
  end

  def comment_params
    params.require(:comment).permit(:body)
  end

  # Ответ на создание: Turbo Stream, который заменяет форму (очищает или показывает ошибки)
  def render_form(comment, status: :ok)
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "comment_form", partial: "comments/form", locals: { trip: @trip, comment: comment }
        ), status: status
      end
      format.html { redirect_to trip_path(@trip) }
    end
  end
end