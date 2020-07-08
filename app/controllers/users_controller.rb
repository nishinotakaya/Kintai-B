class UsersController < ApplicationController
  before_action :set_user, only: [:show, :edit, :update, :destroy, :edit_basic_info, :update_basic_info] #before_actionは一番最初に定義される！
  before_action :logged_in_user, only: [:index, :show, :edit, :destroy, :edit_basic_info, :update_basic_info]
  before_action :correct_user, only: [:edit, :update]
  before_action :admin_user, only: [:index, :update, :destroy, :update_basic_info, :edit_basic_info]
  before_action :admin_or_correct_user, only: :show
  before_action :set_one_month, only: :show
  

  def index
    @users = User.paginate(page: params[:page])
    if params[:search].present?
      @users = @Users.search(params[:search])
    end
  end
   
 
    
  
  def import
    if params[:file].blank?
      flash[:warning] = "CSVファイルが選択されていません。"
    else  
    # fileはtmpに自動で一時保存される
      User.import(params[:file])
      flash[:success] = "ユーザー情報をインポートしました。"  
      redirect_to users_url
    end
  end
  
 
 
  def show
    @worked_sum = @attendances.where.not(started_at: nil).count
    @overwork_count = Attendance.where(overtime_status: "申請中", instructor_confirmation: @user.name).count #残業申請のお知らせの件数
    @edit_one_month_count = Attendance.where(before_started_at: (1.days.ago)..(Time.now), before_finished_at: (1.days.ago)..(Time.now), instructor_confirmation: @user.name).count #勤怠変更更新のお知らせ件数
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      log_in @user
      flash[:success] = '新規作成に成功しました。'
      redirect_to @user
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @user.update_attributes(user_params)
      flash[:success] = "ユーザー情報を更新しました。"
      redirect_to @user
    else
      render :index      
    end
  end

  def destroy
    @user.destroy
    flash[:success] = "#{@user.name}のデータを削除しました。"
    redirect_to users_url
  end

  def edit_basic_info
  end

  def update_basic_info
    if @user.update_attributes(basic_info_params)
      flash[:success] = "#{@user.name}の基本情報を更新しました。"
    else
      flash[:danger] = "#{@user.name}の更新は失敗しました。<br>" + @user.errors.full_messages.join("<br>")
    end
    redirect_to users_url
  end
  
  def working_employee_list
    @users = User.all.includes(:attendances)
  end 
  
  
  
  

private

    

    def user_params
      params.require(:user).permit(:name, :email, :department, :affiliation, :password, :password_confirmation, :employee_number, :uid, :designated_work_start_time, :designated_work_end_time)
    end

    def basic_info_params
      params.require(:user).permit(:basic_time, :work_time)
    end
    
    def set_user
      @user = User.find(params[:id])
    end

    # ログイン済みのユーザーか確認します。
    def logged_in_user
      unless logged_in?
        store_location
        flash[:danger] = "ログインしてください。"
        redirect_to login_url
      end
    end

    # アクセスしたユーザーが現在ログインしているユーザーか確認します。
    def correct_user
      redirect_to(root_url) unless current_user?(@user)
    end

    # システム管理権限所有かどうか判定します。
    def admin_user
      redirect_to root_url unless current_user.admin?
    end
    
    def admin_or_correct_user
      @user = User.find(params[:user_id]) if @user.blank?
      unless current_user?(@user) || current_user.admin?
        flash[:danger] = "編集権限がありません。"
        redirect_to(root_url)
      end  
    end
    
    
end