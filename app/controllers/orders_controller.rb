class OrdersController < ApplicationController
  before_filter :authenticate_user!, :only => :show
  before_filter :normalize_params,   :only => [:new, :create]

  def create
    if user.valid? && order.valid?
      user.save_with_customer!(order.subscription? ? order.package.id.to_s : nil)
      order.save_with_payment!
      sign_in user
      redirect_to order, notice: "Thank you for your support!"
    else
      p user.errors, order.errors
      render :new
    end
  end

  protected

    helper_method :user, :order, :billing_address, :shipping_address, :subscription?
    delegate :billing_address, :shipping_address, to: :order

    def user
      @user ||= current_user || User.new(params[:user])
    end

    def order
      @order ||= if params[:action].to_sym == :show
        user.orders.find(params[:id])
      else
        user.orders.build(params[:order])
      end
    end

    def subscription?
      !!params[:subscription]
    end

    def normalize_params
      params[:order] ||= { package: params[:package] || 'tiny', subscription: subscription? }
      [:billing, :shipping].each { |kind| normalize_address_params(kind) }
    end

    def normalize_address_params(kind)
      params[:order][:"#{kind}_address_attributes"] ||= { name: user.name }
      params[:order][:"#{kind}_address_attributes"][:kind] = kind
    end
end
