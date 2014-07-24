class UsersController < ApplicationController

  before_action :get_classroom
  before_action :get_user, except: [:index]
  after_action :verify_authorized

  def index
    authorize @classroom, :people?
    @admins = @classroom.admins.order('first_name')
    @mentors = @classroom.mentors.order('first_name')
    @members = @classroom.members.order('first_name')
  end

  def update
    authorize @classroom, :promote?
    classroom_user = @user.classroom_users.where(classroom: @classroom).first
    classroom_user.role = params[:role]
    classroom_user.save
    role = @user.role(@classroom)

    respond_to do |format|
      format.json {
        render json: {role: role, id: @user.id} , status: :ok
      }
    end
  end

  def destroy
    if @user == @classroom.owner
      raise Pundit::NotAuthorizedError, "Cannot remove owner"
    elsif @user.admin?(@classroom)
      authorize @classroom, :remove_admin?
    else
      authorize @classroom, :remove_student?
    end
    @classroom.users.delete(@user)

    respond_to do |format|
      format.json {
        render json: { id: params[:id] }
      }
    end
  end

  def pass_ownership
    authorize @classroom, :pass_ownership?
    @classroom.owner = @user
    @classroom.save

    respond_to do |format|
      format.json {
        render json: { id: @classroom.owner.id } , status: :ok
      }
    end
  end

  private
  def get_user
    @user = @classroom.users.find(params[:id])
  end
end
