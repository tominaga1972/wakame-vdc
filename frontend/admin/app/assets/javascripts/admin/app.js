//Top-level namespaces for our code

( function () {

  _.templateSettings = {
    interpolate: /\{\{(.+?)\}\}/g,
    evaluate: /\{%(.+?)%\}/g,
    escape: /\{%-(.+?)%\}/g
  };

  window.app = {};
  app.router = {};
  app.collections = {};
  app.models = {};
  app.views = {};
  app.mixins = {};
  app.helpers = {};
  app.info = {
    api_endpoints: {
     admin: '',
     dcmgr: '',
     dcmgr_gui: ''
     }
  };
  app.utils = {};

  app.utils.parsedSearch = function(word) {
    var parsedSearch;
    parsedSearch = app.parsedSearch || (function() {
      var match, re, ret;
      re = /\??(.*?)=([^\&]*)&?/gi;
      ret = {};
      while (match = re.exec(document.location.search)) {
        ret[match[1]] = match[2];
      }
      return app.parsedSearch = ret;
    })();

    if(_.has(parsedSearch, word) ){
      return parsedSearch[word];
    } else{
      return parsedSearch;
    }
  };

  app.DatetimePicker = function(config) {
    this.el = {};
    this.icon = {};
    this.initialize(config);
  };
  _.extend(app.DatetimePicker.prototype, {
    initialize : function(config) {

      var input_form_id = config.input_form_id;
      var icon_id = config.icon_id;
      var self = this;
      this.el = $(input_form_id);
      this.icon = $(icon_id);

      this.el.datetimepicker({
        showSecond: true,
        timeFormat: 'hh:mm:ss',
        dateFormat: 'yy/mm/dd',
        stepHour: 2,
        stepMinute: 10,
        stepSecond: 10,
      });

      this.el.unbind('focus');
      this.icon.click(function() {
        self.el.datetimepicker('show');
      });

    }
  });

  app.Notify = function() {};
  _.extend(app.Notify.prototype, {
    el: '#notify',

    notify: function(type, message, options) {
      options || (options = {});
      var default_options = {
        closable: false,
        fadeOut: {
          enabled: true,
          delay: 2000
        }
      };

      options = _.defaults(options, default_options);
      options = _.extend(options, {
        message: { text: message },
        type: type
      });

      $(this.el).notify(options).show();
    },

    success: function(message, options) {
      this.notify('success', message, options);
    },

    warning: function(message, options) {
      this.notify('warning', message, options);
    },

    info: function(message, options) {
      this.notify('info', message, options);
    },

    error: function(message, options) {
      this.notify('danger', message, options);
    }
  });

  app.notify = new app.Notify;

  //  dropdown menu for top navigations
  $('.dropdown-toggle').dropdown();

})();

