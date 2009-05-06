class ExpensesController < ApplicationController
  # in_place_edit_for :expense, :category
  def set_expense_category
    @expense = Expense.find(params[:id])
    if category = Category.find(params[:value])
      @expense.update_attribute(:category_id, category.id)
      render :text => category.name, :layout => false
    else
      render :text => "No category with ID #{params[:value]}", :status => 422
    end
  end

  def get_expense_category
    @expense = Expense.find_by_id(params[:id])
    if @expense && @expense.category_id
      render :text => @expense.category_id.to_s, :layout => false
    else
      render :text => "", :status => 422
    end
  end

  # GET /expenses
  # GET /expenses.xml
  def index
    # TODO - limit to when for params[:year]
    options = { :order => '`when`, `vendor`' }
    unless params[:year].blank?
      options[:conditions] = ['YEAR(`when`) = ? ', params[:year].to_i]
    end
    @expenses = Expense.find(:all, options)
    @category_choices = Category.choices_for_select

    total = Expense.new(:vendor => "Grand Total", :when => Time.at(0), :amount => 0.0)
    @expenses.each do |e|
      if e.when > total.when
        total.when = e.when
      end
      total.amount += e.amount
    end

    if params[:subtotals]
      by_cat = @expenses.group_by {|e| e.category_id}
      by_cat.each do |category_id, expenses|
        subtotal = Expense.new(:vendor => "- Subtotal", :category_id => category_id,
                               :when => Time.at(0), :amount => 0.0)
        expenses.each do |e|
          if e.when > subtotal.when
            subtotal.when = e.when
          end
          subtotal.amount += e.amount
        end
        expenses.unshift subtotal
      end
      @expenses = []
      by_cat.keys.sort_by {|cid| Category.find(cid).position}.each do |cat|
        @expenses.concat by_cat[cat]
      end
    end

    @expenses.unshift total
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @expenses }
    end
  end

  # GET /expenses/1
  # GET /expenses/1.xml
  def show
    @expense = Expense.find(params[:id])
    @category_choices = Category.choices_for_select

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @expense }
    end
  end

  # GET /expenses/new
  # GET /expenses/new.xml
  def new
    last = params[:last] ? Time.parse(params[:last]) : Time.now
    @expense = Expense.new(:when => last)
    @category_choices = Category.choices_for_select

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @expense }
    end
  end

  # GET /expenses/1/edit
  def edit
    @expense = Expense.find(params[:id])
    @category_choices = Category.choices_for_select
  end

  # POST /expenses
  # POST /expenses.xml
  def create
    @expense = Expense.new(params[:expense])
    @expense.when = Time.now.beginning_of_day if @expense.when.blank?

    respond_to do |format|
      if @expense.save
        flash[:notice] = 'Expense was successfully created.'
        format.html { redirect_to new_expense_url(:last => @expense.when.iso8601) }
        format.xml  { render :xml => @expense, :status => :created, :location => @expense }
      else
        format.html { @category_choices = Category.choices_for_select
                      render :action => "new" }
        format.xml  { render :xml => @expense.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /expenses/1
  # PUT /expenses/1.xml
  def update
    @expense = Expense.find(params[:id])

    respond_to do |format|
      if @expense.update_attributes(params[:expense])
        flash[:notice] = 'Expense was successfully updated.'
        format.html { redirect_to expenses_url }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @expense.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /expenses/1
  # DELETE /expenses/1.xml
  def destroy
    if @expense = Expense.find_by_id(params[:id])
      @expense.destroy
    end

    respond_to do |format|
      format.html { redirect_to expenses_url(:year => params[:year], :subtotals => !params[:subtotals].blank?) }
      format.xml  { head :ok }
    end
  end
end
