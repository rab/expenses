# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  COLORS = Hash.new('#ff0000').merge!({ :notice => '#00ff00',
                                        :warning => '#ff9900',
                                        :error   => '#ff0000',
                                      }) unless const_defined? 'COLORS'
  def flash_div(*keys)
    keys.collect { |key|
      content_tag(:div, flash[key],
                  :id => "#{key}",
                  :class => "flash") if flash[key]
    }.join +
      keys.collect { |key|
      javascript_tag(visual_effect(:highlight, "#{key}",
                                   :startcolor => "#{COLORS[key]}",
                                   :endcolor   => "#ffffff")) if flash[key]
    }.join
  end

  # Example:
  # class Soldier < ActiveRecord::Base; belongs_to :rank;   end
  # class Rank    < ActiveRecord::Base; has_many :soldiers; attr_accessible :name; end
  #
  # Arguments:
  # <tt>object</tt>::          The actual object containing the field (e.g.,
  #                            <strong>@soldier</strong> =
  #                            Soldier.find(params[:id]))
  # <tt>obj_name</tt>::        The name to be used for constructing HTML id's
  #                            and such (e.g., 'soldier' which becomes a
  #                            problem if abject is expected to be
  #                            instance_get("@#{obj_name}"), but it's
  #                            actaually a local in a partial)
  # <tt>method</tt>::          The +String+ naming the method for the association (e.g., 'rank')
  # <tt>choices</tt>::         +:all+ means get them from the named
  #                            association with the 'text' coming from :name
  #                            and 'value' coming from :id, otherwise, a
  #                            +container+ fitting the description from
  #                            +options_for_select+

  def in_place_collection_field(object, obj_name, method, choices,
                                tag_options = {},
                                in_place_selector_options = {})
    tag = ::ActionView::Helpers::InstanceTag.new(obj_name, method, self, nil, object)
    choices = object.send(method).class.find(:all).collect {|o| [o.name, o.id] } if choices == :all
    tag_options = { :tag => "span", :class => "in_place_select_field",
      :id => "#{obj_name}_#{method}_#{object.id}_in_place_selector"}.merge!(tag_options)
    in_place_selector_options[:url] ||= url_for({ :action => "set_#{obj_name}_#{method}",
                                                  :id => object.id })
    # in_place_selector_options = { :ok_button => false, :submit_on_blur => true }.merge!(in_place_selector_options)
    name = object.send(method).name rescue '(none)'
    content_tag(tag_options.delete(:tag), name, tag_options) +
      in_place_collection_editor(tag_options[:id], choices, in_place_selector_options)
  end

  #--
  # file:///Users/rab/Consulting/Stylepath/svk/doc/api/classes/ActionView/Helpers/JavaScriptMacrosHelper.html#M000569
  #
  # Based on ActionView::Helpers::JavaScriptMacrosHelper::in_place_editor
  # from Rails 1.2.2 (ActionPack 1.13.2)
  # vendor/rails/actionpack/lib/action_view/helpers/java_script_macros_helper.rb
  #++
  # ----
  #
  # Makes an HTML element specified by the DOM ID +field_id+ become an in-place
  # editor of a property using a <tt>&lt;select%gt;</tt> element.
  #
  # It is as if a form is automatically created and displayed when the user
  # clicks the element, something like this:
  #   <form id="myElement-in-place-edit-form" target="specified url">
  #     <input name="value" text="The content of myElement"/>
  #     <select>
  #       <option value="1">chair</option>
  #       <option value="2">easel</option>
  #       <option value="4" selected="selected">stool</option>
  #       <option value="5">table</option>
  #       <option value="6">armoire</option>
  #     </select>
  #     <a onclick="javascript to cancel the editing">cancel</a>
  #   </form>
  #
  # The form is serialized and sent to the server using an AJAX call, the action on
  # the server should process the value and return the updated value in the body of
  # the reponse. The element will automatically be updated with the changed value
  # (as returned from the server).
  #
  # Required +options+ are:
  # <tt>:url</tt>::       Specifies the url where the updated value should
  #                       be sent after the user presses "ok".
  #
  # Addtional +options+ are:
  # <tt>:cancel_text</tt>::       The text on the cancel link. (default: "cancel")
  # <tt>:save_text</tt>::         The text on the save link. (default: "ok")
  # <tt>:loading_text</tt>::      The text to display while the data is being loaded from the server (default: "Loading...")
  # <tt>:saving_text</tt>::       The text to display when submitting to the server (default: "Saving...")
  # <tt>:external_control</tt>::  The id of an external control used to enter edit mode.
  # <tt>:load_text_url</tt>::     URL where initial value of editor (content) is retrieved.
  # <tt>:options</tt>::           Pass through options to the AJAX call (see prototype's Ajax.Updater)
  # <tt>:with</tt>::              JavaScript snippet that should return what is to be sent
  #                               in the AJAX call, +form+ is an implicit parameter
  # <tt>:script</tt>::            Instructs the in-place editor to evaluate the remote JavaScript response (default: false)
  # <tt>:click_to_edit_text</tt>::The text shown during mouseover the editable text (default: "Click to edit")

  def in_place_collection_editor(field_id, choices=[], options = {})
    function =  "new Ajax.InPlaceCollectionEditor("
    function << "'#{field_id}', "
    function << "'#{url_for(options[:url])}'"

    js_options = {}

    js_options['collection'] = choices.map {|choice| [ choice.last, choice.first ] }.to_json

    js_options['okButton'] = options[:ok_button] if options.has_key?(:ok_button)
    js_options['submitOnBlur'] = options[:submit_on_blur] if options.has_key?(:submit_on_blur)
    js_options['okText'] = %('#{options[:save_text]}') if options[:save_text]
    js_options['cancelText'] = %('#{options[:cancel_text]}') if options[:cancel_text]
    js_options['loadingText'] = %('#{options[:loading_text]}') if options[:loading_text]
    js_options['loadTextURL'] = "'#{url_for(options[:load_text_url])}'" if options[:load_text_url]
    js_options['savingText'] = %('#{options[:saving_text]}') if options[:saving_text]
    js_options['callback']   = "function(form) { return #{options[:with]} }" if options[:with]

    js_options['externalControl'] = "'#{options[:external_control]}'" if options[:external_control]
    js_options['ajaxOptions'] = options[:options] if options[:options]

    js_options['evalScripts'] = options[:script] if options[:script]
    js_options['paramName'] = %('#{options[:param_name]}') if options[:param_name]
    js_options['highlightcolor'] = %('#{options[:highlightcolor]}') if options[:highlightcolor]
    js_options['highlightendcolor'] = %('#{options[:highlightendcolor]}') if options[:highlightendcolor]
    js_options['onFailure'] = %('#{options[:on_failure]}') if options[:on_failure]
    js_options['savingClassName'] = %('#{options[:saving_class_name]}') if options[:saving_class_name]
    js_options['clickToEditText'] = %('#{options[:click_to_edit_text]}') if options[:click_to_edit_text]
    js_options['cancelLink'] = options[:cancel_link] if options.has_key?(:cancel_link)

    function << (', ' + options_for_javascript(js_options)) unless js_options.empty?

    function << ')'

    javascript_tag(function)
  end

end
