class ExpensesController < ApplicationController
  before_action :require_login
  before_action :set_trip

  def create
    @expense = @trip.expenses.build(expense_params)
    @expense.user = current_user

    if @expense.save
      render_form(Expense.new(spent_on: Date.current))
    else
      render_form(@expense, status: :unprocessable_entity)
    end
  end

  # Участник удаляет свои расходы, владелец любые
  def destroy
    scope = @trip.owner?(current_user) ? @trip.expenses : @trip.expenses.where(user: current_user)
    scope.find(params[:id]).destroy
    redirect_to trip_path(@trip), notice: "Расход удалён.", status: :see_other
  end

  private

  def set_trip
    @trip = current_user.accessible_trips.find(params[:trip_id])
  end

  def expense_params
    params.require(:expense).permit(:title, :amount, :category, :spent_on)
  end

  def render_form(expense, status: :ok)
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "expense_form", partial: "expenses/form", locals: { trip: @trip, expense: expense }
        ), status: status
      end
      format.html { redirect_to trip_path(@trip) }
    end
  end
end