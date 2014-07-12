// Generated by LiveScript 1.2.0
(function(){
  var define, out$ = typeof exports != 'undefined' && exports || this;
  define = (typeof window != 'undefined' && window !== null ? window.define : void 8) || (typeof plv8 != 'undefined' && plv8 !== null
    ? function(it){
      return it();
    }
    : require('amdefine'));
  define(function(require, exports, module){
    var post, censor, subdomain;
    out$.post = post = this.post = function(post){
      var errors;
      errors = [];
      if (!post.user_id) {
        errors.push('Must Specify A User');
      }
      if (!post.forum_id) {
        errors.push('Forum Cannot Be Blank');
      }
      if (!(post.title || post.parent_id)) {
        errors.push('Title Your Creation!');
      }
      if (!post.body) {
        errors.push('Write Something!');
      }
      return errors;
    };
    out$.censor = censor = this.censor = function(c){
      var errors;
      errors = [];
      if (!c.user_id) {
        errors.push('User Cannot Be Blank');
      }
      if (!c.post_id) {
        errors.push('Post Cannot Be Blank');
      }
      if (!c.reason) {
        errors.push('Reason Cannot Be Blank');
      }
      return errors;
    };
    out$.subdomain = subdomain = this.subdomain = function(subdomain){
      var allowedChars, errors;
      allowedChars = /^[a-z0-9\-]+$/i;
      errors = [];
      if (!subdomain.match(allowedChars)) {
        errors.push('Invalid Subdomain');
      }
      return errors;
    };
    return this;
  });
}).call(this);
