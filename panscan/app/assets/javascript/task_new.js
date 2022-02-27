Opal.queue(function(Opal) {/* Generated by Opal 1.4.1 */
  var self = Opal.top, $nesting = [], $$ = Opal.$r($nesting), nil = Opal.nil, $$$ = Opal.$$$, $eqeq = Opal.eqeq, $send = Opal.send, $gvars = Opal.gvars, $to_a = Opal.to_a, $rb_minus = Opal.rb_minus, $rb_plus = Opal.rb_plus, $lambda = Opal.lambda, $def = Opal.def, $hash2 = Opal.hash2, $truthy = Opal.truthy, $rb_gt = Opal.rb_gt, $neqeq = Opal.neqeq;
  if ($gvars.document == null) $gvars.document = nil;

  Opal.add_stubs('==,[],href=,location,-,+,inner_html=,at_css,call,do_update_page,inner_html,Native,get_params,get_page,get_server_task,update_page,get,on,json,update_task_run,take_action,[]=,post,each,value,flatten,scan,map,filter,!=,gsub,>,size,show,hide,join,ready,open,do_save,do_run,do_fork,update_params,parse,body,meta?,shift?,char,puts,prevent,key');
  
  
  $def(self, '$take_action', function $$take_action(json) {
    var self = this, $writer = nil;
    if ($gvars.$ == null) $gvars.$ = nil;
    if ($gvars.document == null) $gvars.document = nil;

    
    if ($eqeq(json['$[]']("action"), "redirect")) {
      
      $writer = [json['$[]']("to")];
      $send($gvars.$.$location(), 'href=', $to_a($writer));
      $writer[$rb_minus($writer["length"], 1)];
    };
    if ($eqeq(json['$[]']("action"), "open")) {
      
      $writer = [json['$[]']("to")];
      $send($gvars.$.$location(), 'href=', $to_a($writer));
      $writer[$rb_minus($writer["length"], 1)];
    };
    if ($eqeq(json['$[]']("action"), "message")) {
      
      
      $writer = [$rb_plus(" | Message: ", json['$[]']("message"))];
      $send($gvars.document.$at_css("#message"), 'inner_html=', $to_a($writer));
      $writer[$rb_minus($writer["length"], 1)];;
      $gvars.$['$[]']("setTimeout").$call($lambda(function $$1(){        if ($gvars.document == null) $gvars.document = nil;

        
        $writer = [""];
        $send($gvars.document.$at_css("#message"), 'inner_html=', $to_a($writer));
        return $writer[$rb_minus($writer["length"], 1)];}, 0), 5000);
      return self.$do_update_page();
    } else {
      return nil
    };
  }, 1);
  
  $def(self, '$get_page', function $$get_page() {
    var self = this, tid = nil, status = nil, code = nil, json = nil;
    if ($gvars.document == null) $gvars.document = nil;

    
    tid = $gvars.document.$at_css("#tid").$inner_html();
    status = $gvars.document.$at_css("#status").$inner_html();
    code = self.$Native(editor.getValue());
    return (json = $hash2(["status", "tid", "code", "params"], {"status": status, "tid": tid, "code": code, "params": self.$get_params()}));
  }, 0);
  
  $def(self, '$do_update_page', function $$do_update_page() {
    var self = this, json = nil;

    
    json = self.$get_page();
    return $send(self, 'get_server_task', [json['$[]']("tid")], function $$2(task){var self = $$2.$$s == null ? this : $$2.$$s;

      
      
      if (task == null) task = nil;;
      return self.$update_page(task);}, {$$arity: 1, $$s: self});
  }, 0);
  
  $def(self, '$update_page', function $$update_page(json) {
    var $writer = nil;
    if ($gvars.document == null) $gvars.document = nil;

    
    
    $writer = [json['$[]']("tid")];
    $send($gvars.document.$at_css("#tid"), 'inner_html=', $to_a($writer));
    $writer[$rb_minus($writer["length"], 1)];;
    
    $writer = [json['$[]']("name")];
    $send($gvars.document.$at_css("#name"), 'inner_html=', $to_a($writer));
    $writer[$rb_minus($writer["length"], 1)];;
    
    $writer = [json['$[]']("run_timestamp")];
    $send($gvars.document.$at_css("#run_timestamp"), 'inner_html=', $to_a($writer));
    $writer[$rb_minus($writer["length"], 1)];;
    
    $writer = [json['$[]']("save_timestamp")];
    $send($gvars.document.$at_css("#save_timestamp"), 'inner_html=', $to_a($writer));
    $writer[$rb_minus($writer["length"], 1)];;
    
    $writer = [json['$[]']("updated_at")];
    $send($gvars.document.$at_css("#updated_at"), 'inner_html=', $to_a($writer));
    $writer[$rb_minus($writer["length"], 1)];;
    
    $writer = [json['$[]']("status")];
    $send($gvars.document.$at_css("#status"), 'inner_html=', $to_a($writer));
    $writer[$rb_minus($writer["length"], 1)];;
    
    $writer = [json['$[]']("runner")];
    $send($gvars.document.$at_css("#runner"), 'inner_html=', $to_a($writer));
    $writer[$rb_minus($writer["length"], 1)];;
    
    $writer = [json['$[]']("output")];
    $send($gvars.document.$at_css("#output"), 'inner_html=', $to_a($writer));
    $writer[$rb_minus($writer["length"], 1)];;
    
    $writer = [json['$[]']("return")];
    $send($gvars.document.$at_css("#return"), 'inner_html=', $to_a($writer));
    return $writer[$rb_minus($writer["length"], 1)];;
  }, 1);
  
  $def(self, '$get_server_task', function $$get_server_task(tid) {
    var $yield = $$get_server_task.$$p || nil, self = this;

    delete $$get_server_task.$$p;
    return $send($$$($$('Browser'), 'HTTP'), 'get', ["/task/json/" + (tid)], function $$3(){var self = $$3.$$s == null ? this : $$3.$$s;

      return $send(self, 'on', ["success"], function $$4(res){
        
        
        if (res == null) res = nil;;
        return Opal.yield1($yield, res.$json());;}, 1)}, {$$arity: 0, $$s: self})
  }, 1);
  
  $def(self, '$update_task_run', function $$update_task_run() {
    var self = this, json = nil;

    
    json = self.$get_page();
    if (($eqeq(json['$[]']("status"), "run") || ($eqeq(json['$[]']("status"), "open")))) {
      return $send(self, 'get_server_task', [json['$[]']("tid")], function $$5(task){var self = $$5.$$s == null ? this : $$5.$$s;
        if ($gvars.$ == null) $gvars.$ = nil;

        
        
        if (task == null) task = nil;;
        self.$update_page(task);
        return $gvars.$['$[]']("setTimeout").$call($lambda(function $$6(){var self = $$6.$$s == null ? this : $$6.$$s;

          return self.$update_task_run()}, {$$arity: 0, $$s: self}), 1000);}, {$$arity: 1, $$s: self})
    } else {
      return nil
    };
  }, 0);
  
  $def(self, '$do_run', function $$do_run() {
    var self = this, json = nil, $writer = nil;

    
    json = self.$get_page();
    if (($eqeq(json['$[]']("status"), "run") || ($eqeq(json['$[]']("status"), "open")))) {
      return self.$take_action($hash2(["action", "message"], {"action": "message", "message": "task is waiting for run"}))
    } else {
      
      
      $writer = ["return", ""];
      $send(json, '[]=', $to_a($writer));
      $writer[$rb_minus($writer["length"], 1)];;
      
      $writer = ["runner", ""];
      $send(json, '[]=', $to_a($writer));
      $writer[$rb_minus($writer["length"], 1)];;
      
      $writer = ["output", ""];
      $send(json, '[]=', $to_a($writer));
      $writer[$rb_minus($writer["length"], 1)];;
      
      $writer = ["status", "open"];
      $send(json, '[]=', $to_a($writer));
      $writer[$rb_minus($writer["length"], 1)];;
      self.$update_page(json);
      return $send($$$($$('Browser'), 'HTTP'), 'post', ["/task/run", json], function $$7(){var self = $$7.$$s == null ? this : $$7.$$s;

        return $send(self, 'on', ["success"], function $$8(res){var self = $$8.$$s == null ? this : $$8.$$s;
          if ($gvars.$ == null) $gvars.$ = nil;

          
          
          if (res == null) res = nil;;
          self.$take_action(res.$json());
          return $gvars.$['$[]']("setTimeout").$call($lambda(function $$9(){var self = $$9.$$s == null ? this : $$9.$$s;

            return self.$update_task_run()}, {$$arity: 0, $$s: self}), 1000);}, {$$arity: 1, $$s: self})}, {$$arity: 0, $$s: self});
    };
  }, 0);
  
  $def(self, '$do_save', function $$do_save() {
    var self = this;

    return $send($$$($$('Browser'), 'HTTP'), 'post', ["/task/save", self.$get_page()], function $$10(){var self = $$10.$$s == null ? this : $$10.$$s;

      return $send(self, 'on', ["success"], function $$11(res){var self = $$11.$$s == null ? this : $$11.$$s;

        
        
        if (res == null) res = nil;;
        return self.$take_action(res.$json());}, {$$arity: 1, $$s: self})}, {$$arity: 0, $$s: self})
  }, 0);
  
  $def(self, '$do_fork', function $$do_fork() {
    var self = this;

    return $send($$$($$('Browser'), 'HTTP'), 'post', ["/task/fork", self.$get_page()], function $$12(){var self = $$12.$$s == null ? this : $$12.$$s;

      return $send(self, 'on', ["success"], function $$13(res){var self = $$13.$$s == null ? this : $$13.$$s;

        
        
        if (res == null) res = nil;;
        return self.$take_action(res.$json());}, {$$arity: 1, $$s: self})}, {$$arity: 0, $$s: self})
  }, 0);
  
  $def(self, '$get_params', function $$get_params() {
    var ret = nil;
    if ($gvars.params == null) $gvars.params = nil;

    
    ret = $hash2([], {});
    $send($gvars.params, 'each', [], function $$14(param){var $writer = nil;
      if ($gvars.document == null) $gvars.document = nil;

      
      
      if (param == null) param = nil;;
      $writer = [param, $gvars.document.$at_css($rb_plus("#", param)).$value()];
      $send(ret, '[]=', $to_a($writer));
      return $writer[$rb_minus($writer["length"], 1)];}, 1);
    return ret;
  }, 0);
  
  $def(self, '$update_params', function $$update_params(init_params) {
    var self = this, json = nil, param_json = nil, code = nil, params = nil, params_html = nil, $writer = nil;
    if ($gvars.document == null) $gvars.document = nil;
    if ($gvars.params == null) $gvars.params = nil;

    
    
    if (init_params == null) init_params = nil;;
    json = self.$get_page();
    param_json = json['$[]']("params");
    if ($truthy(init_params)) {
      param_json = init_params
    };
    code = json['$[]']("code");
    params = code.$scan(/(__[a-zA-Z0-9_]+__)/).$flatten();
    params = $send($send(params, 'filter', [], function $$15(x){
      
      
      if (x == null) x = nil;;
      return x['$!=']("__TASK_NAME__");}, 1), 'map', [], function $$16(x){
      
      
      if (x == null) x = nil;;
      return x.$gsub(/^__/, "").$gsub(/__$/, "");}, 1);
    if ($truthy($rb_gt(params.$size(), 0))) {
      $gvars.document.$at_css("#params_box").$show()
    } else {
      $gvars.document.$at_css("#params_box").$hide()
    };
    if ($neqeq(params, $gvars.params)) {
      
      params_html = $send(params, 'map', [], function $$17(param){
        
        
        if (param == null) param = nil;;
        return "<tr><td>" + (param) + "</td><td> = </td><td><input id='" + (param) + "' type='text' name='" + (param) + "' value='" + (param_json['$[]'](param)) + "' ></td></tr>";}, 1).$join("\n");
      params_html = "<table>" + (params_html) + "</table>";
      
      $writer = [params_html];
      $send($gvars.document.$at_css("#params"), 'inner_html=', $to_a($writer));
      $writer[$rb_minus($writer["length"], 1)];;
      return ($gvars.params = params);
    } else {
      return nil
    };
  }, -1);
  return $send($gvars.document, 'ready', [], function $$18(){var self = $$18.$$s == null ? this : $$18.$$s, init_params = nil, json = nil;
    if ($gvars.document == null) $gvars.document = nil;
    if ($gvars.$ == null) $gvars.$ = nil;

    
    $gvars.params = $hash2([], {});
    $gvars.meta_down = false;
    $gvars.shift_down = false;
    $send($gvars.document.$at_css("#save"), 'on', ["click"], function $$19(){var self = $$19.$$s == null ? this : $$19.$$s;
      if ($gvars.window == null) $gvars.window = nil;

      
      $gvars.window.$open("http://www.google.com");
      return self.$do_save();}, {$$arity: 0, $$s: self});
    $send($gvars.document.$at_css("#run"), 'on', ["click"], function $$20(){var self = $$20.$$s == null ? this : $$20.$$s;

      return self.$do_run()}, {$$arity: 0, $$s: self});
    $send($gvars.document.$at_css("#fork"), 'on', ["click"], function $$21(){var self = $$21.$$s == null ? this : $$21.$$s;

      return self.$do_fork()}, {$$arity: 0, $$s: self});
    init_params = $gvars.document.$at_css("#init_params").$inner_html();
    json = self.$get_page();
    self.$update_params($$('JSON').$parse(($eqeq(init_params, "") ? ("{}") : (init_params))));
    self.$update_task_run();
    $gvars.$['$[]']("setInterval").$call($lambda(function $$22(){var self = $$22.$$s == null ? this : $$22.$$s;

      return self.$update_params()}, {$$arity: 0, $$s: self}), 1000);
    $send($gvars.document.$body(), 'on', ["keydown"], function $$23(e){var self = $$23.$$s == null ? this : $$23.$$s;

      
      
      if (e == null) e = nil;;
      if ($truthy(e['$meta?']())) {
        $gvars.meta_down = true
      };
      if ($truthy(e['$shift?']())) {
        $gvars.shift_down = true
      };
      if (($truthy(e['$meta?']()) && ($eqeq(e.$char(), "S")))) {
        
        self.$puts("save task");
        self.$do_save();
        e.$prevent();
      };
      if (($truthy(e['$shift?']()) && ($eqeq(e.$key(), "Enter")))) {
        
        self.$puts("run task");
        self.$do_run();
        return e.$prevent();
      } else {
        return nil
      };}, {$$arity: 1, $$s: self});
    return $send($gvars.document.$body(), 'on', ["keyup"], function $$24(e){
      
      
      if (e == null) e = nil;;
      if ($truthy(e['$meta?']())) {
        $gvars.meta_down = false
      };
      if ($truthy(e['$shift?']())) {
        return ($gvars.shift_down = false)
      } else {
        return nil
      };}, 1);}, {$$arity: 0, $$s: self});
});

//# sourceMappingURL=task_new.js.map