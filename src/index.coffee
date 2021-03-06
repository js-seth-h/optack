debug =  require('debug')('optack')
 
{ficent} = require 'ficent'
_ = require 'lodash'

 
module.exports = 
createOpTack = (steps)->  

  return create_fn = (op_args...)-> 
    delegate_op = null
    [parts, delegate_op ] = op_args if op_args.length is 2
    [parts] = op_args if op_args.length is 1


    opTackFn = (args..., cb)->    
      opTackFn.run args..., cb 


    # 최상위의 부모를 제작
    unless delegate_op
      delegate_op = definition : Object.create(null)
      delegate_op.definition.__type__ = 'opTack-def' 
      _.forEach steps, (step_name)->
        if steps is 'finalize'
          delegate_op.definition[step_name] = (err, args..., _toss)-> _toss err
        else
          delegate_op.definition[step_name] = (args..., _toss)-> _toss null 
    
    opTackFn.definition = Object.create delegate_op.definition
    opTackFn.definition.__type__ = 'opTack-def'


    # debug 'create opTackFn', 'with', parts
    _.forEach parts, (fn, k)->
      # debug 'set parts', fn, k
      # opTackFn.definition[k] = fn
      # if k not in steps
      if not _.isFunction fn 
        opTackFn.definition[k] = fn
      else if k in steps
        opTackFn.definition[k] = (args..., _toss)->  
          _toss.setItem '_optack_super', Object.getPrototypeOf opTackFn.definition
          _toss.setItem '_optack', this 
          fn.call this, args..., _toss
      else 
        opTackFn.definition[k] = (args...)-> 
          fn.call this, args...
      return # false를 반환하면 _.forEach가 중지된다. 그러니까 명시적 리턴처리
    debug 'opTackFn.definition', opTackFn.definition

    opTackFn.decor = (decor_parts)->
      create_fn decor_parts, opTackFn

    opTackFn.run = (args..., cb)-> 
      # _op_super = Object.getPrototypeOf opTackFn.definition
      run_context = Object.create opTackFn.definition
      # debug 'run_context:', run_context
      # debug 'opTackFn.definition:', opTackFn.definition 
      fn_stack = _.map steps, (step_name)-> 
        if step_name is 'finalize'
          return (err, _toss)->   
            run_context.finalize err, args..., _toss
        else
          return (_toss)->  
            debug 'call step_name:', step_name, 'run_context:', run_context
            run_context[step_name] args..., _toss 
      (ficent fn_stack) cb

    return opTackFn 
