process.env.DEBUG = "test, optack "
opTack = require '../src'
assert = require 'assert'
util = require 'util'

 
debug = require('debug')('test')
 


describe 'basic', ()->    
  it 'create & run', (done)-> 
    opTpl = opTack "cleaning,configure,execute".split ','
    
    acc = 0;
    runable_fn = opTpl 
      cleaning: (callback)-> 
        acc += 1; 
        callback null
      configure: (callback)-> acc += 2;   callback null
      execute: (callback)->acc += 4;  callback null

    runable_fn (err)->
      expect err
        .toEqual null

      expect acc
        .toEqual 7
      done()


  it 'with arg', (done)-> 
    opTpl = opTack "cleaning,configure,execute".split ',' 
    ctx = 
      acc : 10 
    runable_fn = opTpl 
      cleaning: (ctx, callback)-> 
        ctx.acc += 1; 
        callback null
      configure: (ctx, callback)-> ctx.acc += 2; callback null
      execute: (ctx, callback)-> ctx.acc += 4;  callback null

    runable_fn ctx, (err)->
      expect err
        .toEqual null
      expect ctx.acc
        .toEqual 17
      done()



  it 'access context values', (done)-> 
    debug 'access context values'
    opTpl = opTack "cleaning,configure,execute".split ',' 
    ctx = 
      acc : 10 
    runable_fn = opTpl 
      var_in_op: 100
      cleaning: (ctx, callback)-> 
        console.log 'this', this
        ctx.acc += 1 + @var_in_op;
        callback null
      configure: (ctx, callback)-> ctx.acc += 2 + @var_in_op; callback null
      execute: (ctx, callback)-> ctx.acc += 4 + @var_in_op;  callback null

    runable_fn ctx, (err)->
      expect err
        .toEqual null
      expect ctx.acc
        .toEqual 17 + 300
      done()


  it 'access context fn', (done)-> 
    debug 'access context fn'
    opTpl = opTack "cleaning,configure,execute".split ',' 
    ctx = 
      acc : 10 
    runable_fn = opTpl 
      var_in_op: ()-> 100
      cleaning: (ctx, callback)-> 
        console.log 'this', this
        ctx.acc += 1 + @var_in_op();
        callback null
      configure: (ctx, callback)-> ctx.acc += 2 + @var_in_op(); callback null
      execute: (ctx, callback)-> ctx.acc += 4 + @var_in_op();  callback null

    runable_fn ctx, (err)-> 
      debug err  if err
      expect err
        .toEqual null
      expect ctx.acc
        .toEqual 17 + 300
      done()

    

  it 'decor', (done)-> 
    opTpl = opTack "cleaning,configure,execute".split ',' 
    ctx = 
      acc : 0 
    runable_fn = opTpl 
      var_in_op: 100
      cleaning: (ctx, callback)-> 
        ctx.acc += 1; 
        callback null
      configure: (ctx, callback)-> ctx.acc += 2; callback null
      execute: (ctx, callback)-> ctx.acc += 4;  callback null

    runable_fn2 = runable_fn.decor 
      cleaning: (ctx, callback)-> 
        ctx.acc += 11  + @var_in_op; 
        callback null
      configure: (ctx, callback)-> ctx.acc += 22; callback null
      execute: (ctx, callback)-> ctx.acc += 44;  callback null


    runable_fn2 ctx, (err)->
      expect err
        .toEqual null
      expect ctx.acc
        .toEqual 177
      done()

  it 'decor, call override context fn', (done)-> 
    opTpl = opTack "cleaning,configure,execute".split ',' 
    ctx = 
      acc : 0 
    runable_fn = opTpl 
      n10: ()-> 10
      var_in_op: ()-> 100
      cleaning: (ctx, callback)-> 
        ctx.acc += 1; 
        callback null
      configure: (ctx, callback)-> ctx.acc += 2; callback null
      execute: (ctx, callback)-> ctx.acc += 4;  callback null

    runable_fn2 = runable_fn.decor 
      var_in_op: ()-> -100
      cleaning: (ctx, callback)-> 
        ctx.acc += 11  + @var_in_op() + @n10(); 
        callback null
      configure: (ctx, callback)-> ctx.acc += 22; callback null
      execute: (ctx, callback)-> ctx.acc += 44;  callback null


    runable_fn2 ctx, (err)->
      expect err
        .toEqual null
      expect ctx.acc
        .toEqual 77 - 100 + 10
      done()


  it 'decor and call original', (done)-> 
    opTpl = opTack "cleaning,configure,execute".split ',' 
    ctx = 
      acc : 0 
    runable_fn = opTpl 
      cleaning: (ctx, callback)-> 
        ctx.acc += 1; 
        callback null
      configure: (ctx, callback)-> ctx.acc += 2; callback null
      execute: (ctx, callback)-> ctx.acc += 4;  callback null

    runable_fn2 = runable_fn.decor 
      cleaning: (ctx, _toss)-> 
        ctx.acc += 11; 
        {_optack, _optack_super} = _toss.items()
        _optack_super.cleaning.call _optack, ctx, _toss

      configure: (ctx, callback)-> ctx.acc += 22; callback null
      execute: (ctx, callback)-> ctx.acc += 44;  callback null


    runable_fn2 ctx, (err)->
      debug err  if err
      expect err
        .toEqual null
      expect ctx.acc
        .toEqual 77 + 1
      done()



  it 'decor 3 time', (done)-> 
    opTpl = opTack "cleaning,configure,execute".split ',' 
    ctx = 
      acc : 0 
    runable_fn = opTpl 
      cleaning: (ctx, callback)-> 
        ctx.acc += 1; 
        callback null
      n1: ()-> 7
      n4: ()-> 3
      configure: (ctx, callback)-> ctx.acc += 2; callback null
      execute: (ctx, callback)-> ctx.acc += 4;  callback null

    runable_fn2 = runable_fn.decor 
      cleaning: (ctx, _toss)-> 
        ctx.acc += 11; 
        {_optack, _optack_super} = _toss.items()
        _optack_super.cleaning.call _optack, ctx, _toss

      n2: ()-> 13
      configure: (ctx, callback)-> ctx.acc += 22; callback null
      execute: (ctx, callback)-> ctx.acc += 44;  callback null

    runable_fn3 = runable_fn2.decor 
      cleaning: (ctx, _toss)-> 
        ctx.acc += 111; 
        ctx.n = @n1() * @n2() * @n4()
        {_optack, _optack_super} = _toss.items()
        _optack_super.cleaning.call _optack, ctx, _toss
      n1: ()-> 17 

    runable_fn3 ctx, (err)->
      debug err  if err
      expect err
        .toEqual null
      expect ctx.acc
        .toEqual 111 + 11 + 1 + 22 + 44
      expect ctx.n
        .toEqual 13 * 17 * 3
      done()



  it 'function level this', (done)-> 
    opTpl = opTack "cleaning,configure,execute".split ',' 

    runable_fn = opTpl 
      cleaning: (new_val, callback)-> 
        if new_val
          @context_var = new_val
        callback null
      configure: (doing, callback)->  callback null
      execute: (doing, callback)-> callback null, @context_var

    runable_fn 7, (err, val)->
      expect err
        .toEqual null
      expect val 
        .toEqual 7
      runable_fn undefined, (err, val)->
        expect err
          .toEqual null
        expect val 
          .toEqual undefined

        runable_fn 11, (err, val)->
          expect err
            .toEqual null
          expect val 
            .toEqual 11
          done()
