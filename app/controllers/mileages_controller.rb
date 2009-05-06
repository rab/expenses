class MileagesController < ApplicationController
  # GET /mileages
  # GET /mileages.xml
  def index
    # TODO - limit to driven_on for params[:year]
    options = { :order => '`driven_on`, `starting`' }
    unless params[:year].blank?
      options[:conditions] = ['YEAR(`driven_on`) = ? ', params[:year].to_i]
    end
    @mileages = Mileage.find(:all, options)

    subtotal = params[:subtotal].blank? ? nil : Mileage.new(:purpose => "Subtotal to #{params[:subtotal]}",
                                                            :driven_on => Date.parse(params[:subtotal]),
                                                            :starting => 0, :ending => 0, :trip => 0)

    total = Mileage.new(:purpose => "Grand Total", :driven_on => Date.jd(0),
                        :starting => 0, :ending => 0, :trip => 0)
    @mileages.each do |m|
      if subtotal
        if m.driven_on <= subtotal.driven_on
          subtotal.starting  = m.starting  if m.starting  < subtotal.starting || subtotal.starting == 0
          subtotal.ending    = m.ending    if m.ending    > subtotal.ending
          subtotal.trip     += m.trip
        end
      end
      total.driven_on = m.driven_on if m.driven_on > total.driven_on
      total.starting  = m.starting  if m.starting  < total.starting || total.starting == 0
      total.ending    = m.ending    if m.ending    > total.ending
      total.trip     += m.trip
    end
    if subtotal
      @mileages.push subtotal.clone
      subtotal.purpose   = "Subtotal after #{params[:subtotal]}"
      subtotal.driven_on = total.driven_on
      subtotal.starting  = subtotal.ending
      subtotal.ending    = total.ending
      subtotal.trip      = total.trip - subtotal.trip
      @mileages.push subtotal
    end
    @mileages.push total
    unless params[:year].blank?
      next_year = Date.new(params[:year].to_i + 1, 1, 1)
      if next_year_start = Mileage.find_by_driven_on_and_trip(next_year, 0)
        @mileages.push next_year_start.clone
      end
    end

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @mileages }
    end
  end

  # GET /mileages/1
  # GET /mileages/1.xml
  def show
    @mileage = Mileage.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @mileage }
    end
  end

  # GET /mileages/new
  # GET /mileages/new.xml
  def new
    if recent = Mileage.find(:first, :order => 'ending DESC')
      @mileage = Mileage.new(:driven_on => 1.day.since(recent.driven_on), :starting => recent.ending)
    else
      @mileage = Mileage.new
    end

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @mileage }
    end
  end

  # GET /mileages/1/edit
  def edit
    @mileage = Mileage.find(params[:id])
  end

  # POST /mileages
  # POST /mileages.xml
  def create
    @mileage = Mileage.new(params[:mileage])

    respond_to do |format|
      if @mileage.save
        flash[:notice] = 'Mileage was successfully created.'
        format.html { redirect_to new_mileage_url }
        format.xml  { render :xml => @mileage, :status => :created, :location => @mileage }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @mileage.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /mileages/1
  # PUT /mileages/1.xml
  def update
    @mileage = Mileage.find(params[:id])

    respond_to do |format|
      if @mileage.update_attributes(params[:mileage])
        flash[:notice] = 'Mileage was successfully updated.'
        format.html { redirect_to mileages_url }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @mileage.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /mileages/1
  # DELETE /mileages/1.xml
  def destroy
    @mileage = Mileage.find(params[:id])
    @mileage.destroy

    respond_to do |format|
      format.html { redirect_to(mileages_url) }
      format.xml  { head :ok }
    end
  end
end
