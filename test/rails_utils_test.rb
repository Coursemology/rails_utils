require 'test_helper'

describe "RailsUtils::ActionViewExtensions" do
  let(:controller) { ActionController::Base.new }
  let(:request)    { ActionDispatch::Request.new(flash: {}) }
  let(:view)       { ActionView::Base.new({}, {}, "") }

  before do
    controller.request = request
    view.controller    = controller
  end

  describe "#page_controller_class" do
    describe "simple controller" do
      let(:controller_class) { "AnimeController" }
      let(:controller_name)  { "anime" }

      it "returns controller name" do
        controller.stub :class, controller_class do
          assert_equal(view.page_controller_class, controller_name)
        end
      end
    end

    describe "nested controller returns underscored name by default" do
      let(:controller_class) { "Super::Awesome::AnimeController" }
      let(:controller_name)  { "super_awesome_anime" }

      it "returns controller name" do
        controller.stub :class, controller_class do
          assert_equal(view.page_controller_class, controller_name)
        end
      end
    end

    describe "nested controller with selector format returns hyphenated name" do
      let(:controller_class) { "Super::Awesome::AnimeController" }
      let(:controller_name)  { "super-awesome-anime" }

      before do
        RailsUtils.configure do |config|
          @rails_selector_format = config.selector_format
          config.selector_format = :hyphenated
        end
      end

      after do
        RailsUtils.configure do |config|
          config.selector_format = @rails_selector_format
        end
      end

      it "returns controller name" do
        controller.stub :class, controller_class do
          assert_equal(view.page_controller_class, controller_name)
        end
      end
    end

    describe "nested controller with selector format of string returns name in specified format" do
      let(:controller_class) { "Super::Awesome::AnimeController" }
      let(:controller_name)  { "super_awesome_anime" }

      before do
        RailsUtils.configure do |config|
          config.selector_format = :underscored
        end
      end

      it "returns controller name" do
        controller.stub :class, controller_class do
          assert_equal(view.page_controller_class, controller_name)
        end
      end
    end
  end

  describe "#page_action_class" do
    # action_name, expected
    [
      [ "index"  , "index"   ],
      [ "show"   , "show"    ],
      [ "new"    , "new"     ],
      [ "create" , "new"     ],
      [ "edit"   , "edit"    ],
      [ "update" , "edit"    ],
      [ "destroy", "destroy" ],
      [ "custom" , "custom"  ],
    ].each do |action_name, expected|
      describe "when ##{action_name}" do
        it "returns #{expected}" do
          controller.stub :action_name, action_name do
            assert_equal(view.page_action_class, expected)
          end
        end
      end
    end
  end

  describe "#page_class" do
    let(:controller_name) { "anime" }
    let(:action_name)     { "custom" }

    it "uses page_controller_class and page_action_class" do
      view.stub :page_controller_class, controller_name do
        view.stub :page_action_class, action_name do
          assert_equal(view.page_class, "#{controller_name} #{action_name}")
        end
      end
    end
  end

  describe "#page_title" do
    let(:controller_name) { "anime" }

    describe 'when translation is missing' do
      let(:action_name)  { "random" }
      let(:default_translation) { "#{controller_name.capitalize} #{action_name.capitalize}" }

      it "combines page_controller_class and page_action_class" do
        view.stub :page_controller_class, controller_name do
          view.stub :page_action_class, action_name do
            assert_equal(view.page_title, default_translation)
          end
        end
      end

      it "uses :default provided by gem user" do
        view.stub :page_controller_class, controller_name do
          view.stub :page_action_class, action_name do
            assert_equal(view.page_title(default: 'my custom default'), 'my custom default')
          end
        end
      end

      it "calling multiple times reuses first result (template renders before layout)" do
        view.stub :page_controller_class, controller_name do
          view.stub :page_action_class, action_name do
            assert_equal(view.page_title(default: 'my custom default'), 'my custom default')
            assert_equal(view.page_title, 'my custom default')
          end
        end
      end
    end

    describe 'when translation is available' do
      let(:action_name) { "show" }

      before { I18n.backend.store_translations("en", { controller_name.to_sym => { action_name.to_sym => { title: "An awesome title" } }}) }

      it "translates page title" do
        view.stub :page_controller_class, controller_name do
          view.stub :page_action_class, action_name do
            assert_equal(view.page_title, "An awesome title")
          end
        end
      end
    end

    describe "when translation is available + interpolations" do
      let(:action_name) { "show" }

      before { I18n.backend.store_translations("en", { controller_name.to_sym => { action_name.to_sym => { title: "An awesome title, %{name}" } }}) }

      it "translates page title" do
        view.stub :page_controller_class, controller_name do
          view.stub :page_action_class, action_name do
            assert_equal(view.page_title(name: "bro"), "An awesome title, bro")
          end
        end
      end
    end
  end

  describe "#javascript_initialization" do
    let(:controller_class) { "Awesome::AnimeController" }
    let(:controller_name)  { "awesome_anime" }

  #   before do
  #     controller.stubs(:class).returns(controller_class)
  #     controller.stubs(:action_name).returns(action_name)
  #   end

    describe "when controller name and action name are standard" do
      let(:action_name) { "custom" }

      it "invokes application" do
        controller.stub :class, controller_class do
          controller.stub :action_name, action_name do
            assert_match("Dummy.init();", view.javascript_initialization)
          end
        end
      end

      it "invokes controller and action javascript" do
        controller.stub :class, controller_class do
          controller.stub :action_name, action_name do
            assert_match("Dummy.#{controller_name}.init();", view.javascript_initialization)
            assert_match("Dummy.#{controller_name}.#{action_name}.init();", view.javascript_initialization)
          end
        end
      end
    end

    describe "when action name is create" do
      let(:action_name) { "create" }

      it "replaces create with new" do
        controller.stub :class, controller_class do
          controller.stub :action_name, action_name do
            assert_match("Dummy.#{controller_name}.new.init();", view.javascript_initialization)
          end
        end
      end
    end

    describe "when action name is update" do
      let(:action_name) { "update" }

      it "replaces update with create" do
        controller.stub :class, controller_class do
          controller.stub :action_name, action_name do
            assert_match("Dummy.#{controller_name}.edit.init();", view.javascript_initialization)
          end
        end
      end
    end

    describe "with a content_for custom js_init_method as an argument" do
      let(:action_name) { "update" }

      it "uses the custom js init method" do
        controller.stub :class, controller_class do
          controller.stub :action_name, action_name do
            view.content_for(:js_init_method) { "custom" }
            assert_match("Dummy.#{controller_name}.custom.init();", view.javascript_initialization)
          end
        end
      end
    end

    describe "without a content_for custom js_init_method as an argument" do
      let(:action_name) { "update" }

      it "does not generate an additional javascript method" do
        controller.stub :class, controller_class do
          controller.stub :action_name, action_name do
            refute_includes("Dummy.#{controller_name}..init();", view.javascript_initialization)
          end
        end
      end
    end
  end

  describe "#flash_messages" do
    def set_flash(key, message)
      controller.flash[key] = message
    end

    # TODO: Remove support for Bootstrap v2.3.2
    # alert-danger is for Bootstrap 3
    # alert-error  is for Bootstrap 2.3.2
    [
      [ :success , /alert alert-success/            , "flash is success" ],
      [ "success", /alert alert-success/            , "flash is success" ],
      [ :notice  , /alert alert-info/               , "flash is notice"  ],
      [ "notice" , /alert alert-info/               , "flash is notice"  ],
      [ :error   , /alert alert-danger alert-error/ , "flash is error"   ],
      [ "error"  , /alert alert-danger alert-error/ , "flash is error"   ],
      [ :alert   , /alert alert-danger alert-error/ , "flash is alert"   ],
      [ "alert"  , /alert alert-danger alert-error/ , "flash is alert"   ],
      [ :custom  , /alert alert-custom/             , "flash is custom"  ],
      [ "custom" , /alert alert-custom/             , "flash is custom"  ]
    ].each do |key, expected_class, expected_message|
      describe "when flash contains #{key} key" do
        before { set_flash key, expected_message }

        it "prints class '#{expected_class}'" do
          assert_match(expected_class, view.flash_messages)
        end

        it "prints message '#{expected_message}'" do
          assert_match(expected_message, view.flash_messages)
        end
      end
    end

    describe "when bootstrap is present" do
      it "can fade in and out" do
        set_flash :alert, "not important"
        assert_match(/fade in/, view.flash_messages)
      end

      it "can be dismissed" do
        set_flash :alert, "not important"
        assert_match(/data-dismiss=.*alert/, view.flash_messages)
      end
    end

    describe "options" do
      it "can allow override of button content (default 'x')" do
        set_flash :alert, "not important"
        assert_match(%r{>x</button>}, view.flash_messages)
        assert_match(%r{button type="button" class="close"}, view.flash_messages(button_html: ''))
      end

      it "can allow override of button css class (default 'close')" do
        set_flash :alert, "not important"
        assert_match(%r{>x</button>}, view.flash_messages)
        assert_match(%r{button type="button" class="abc def"}, view.flash_messages(button_class: 'abc def'))
      end
    end

    it "should strip <script> tags and their content by default" do
      set_flash :alert, "<script>alert('XSS')</script>"
      refute_match("<script>alert('XSS')<script>", view.flash_messages)
      assert_match("", view.flash_messages)
    end

    it "should strip anchor links by default" do
      set_flash :alert, "<a href=\"https://example.org\">example page</a>"
      refute_match("<a href=\"https://example.org\">example page</a>", view.flash_messages)
    end

    it "should strip img links by default" do
      set_flash :alert, "<img src=\"https://example.org/image.jpg\" />"
      assert_match("", view.flash_messages)
    end

    it "should skip flash[:timedout]" do
      set_flash :timedout, "not important"
      assert_equal("", view.flash_messages)
    end

    it "should be `html_safe`ed" do
      set_flash :alert, "not important"

      assert(view.flash_messages.html_safe?)
    end
  end
end
