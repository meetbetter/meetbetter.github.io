---
title: "Go defer panic recover使用"
date: 2021-04-10T14:54:58+08:00
description: ""
draft: false
tags: [golang]
---


总结下defer panic recover的用法和坑，如果你清楚他们的用法，那你可以看下最后的defer的坑，自查一下会不会掉进去。
<!--more-->


下面先介绍概念，再看代码。

defer关键字用来实现延迟处理和资源释放，如果一个函数中调用多个defer会出现类似栈的后入先出效果。defer可以用来优雅的关闭文件描述符，关闭socket连接，解锁操作等。

panic是在程序运行时出现非常严重的错误时抛出异常，之后的函数不再执行，而是顺着原来的函数调用一层层的向上抛出直到main函数中导致进程挂掉——程序崩了。引起panic的原因有：数组访问越界、空指针引用、死锁等，当然还有手动调用panic()。

但panic不是立即向上抛出异常，而是先执行之间已经defer的内容，这时候就可以在defer中拦截异常以保证其他任务不受影响。recover就是专门来做这个的捕手。

下面是他们的基本用法和那些一不注意就掉进去的坑。

## defer 的基本使用

先来看下defer的基本使用：

### defer延迟调用

```go
func f1() {
 defer fmt.Println("1111")

 fmt.Println(2222)
}
```

输出结果：

```shell
2222
1111
```

```go
func f2() {
 i := 10
 defer func() {
  i = 100
 }()

 fmt.Println("i: ", i)
}
```

输出结果：

```shell
i:  10
```

所以我们通常用defer来优雅的关闭文件描述符，解锁等操作：

```go
func f4() error {
 f, err := os.Open("a.txt")
 if err != nil {
  return err
 }

 defer f.Close()

 return nil
}
```

### 多个defer的后入先出

多个defer的执行顺序：

```go
func f1() {
 defer fmt.Println("1111")
 defer fmt.Println("2222")
 defer fmt.Println("3333")
 defer fmt.Println("4444")
}
```

输出结果是：

```shell
4444
3333
2222
1111
```

## panic和recover

首先看下panic的威力：

```go
func f1() {
 fmt.Println("github.com/meetbetter/go-programming")
 panic("boom")
 fmt.Println("f1 end")
}
func main() {
 fmt.Println("main Entry")
 f1()
 fmt.Println("main End")

}
```

从下面的输出结果可以看出panic后会逐层上抛异常，并且panic后的程序得不到执行：

```
main Entry
github.com/meetbetter/go-programming
panic: boom

goroutine 1 [running]:
main.f1()
        /mnt/c/Users/HideOnBush/go/src/myProjects/00-leetcode/05_panic.go:7 +0x96
main.main()
        /mnt/c/Users/HideOnBush/go/src/myProjects/00-leetcode/05_panic.go:12 +0x7f
exit status 2
```

再来看看recover的威力，拦截panic异常抛出：

```go
func f1() {
 defer func() {
  if err := recover(); err != nil {
   fmt.Println(err)
  }
 }()

 panic("github.com/meetbetter/go-programming")

 fmt.Println("看不到我哦")
}

func main() {
 f1()

 fmt.Println("main End")
}
```

## defer使用注意事项

### level1

先看下这个level1级别的坑：

```go
func f() (result int) {
 defer func() {
  result++
 }()
 return 100
}

func main() {
 fmt.Println(f())

}
```

输出结果是100吗？
不对，是101。这儿是因为return时分为两步：给返回值result赋值 --> 执行defer。所以外面接收到的返回值是100+1。

### level2

再来看个level2的，下面的输出为什么不一样：

```go

func f1() {

 i := 0
 defer func(i int) {
  fmt.Println("defer func: ", i)
 }(i)

 i = 100

}

func f2() {

 i := 0
 defer func() {
  fmt.Println("defer func: ", i)
 }()

 i = 100

}
func main() {

 f1()
 f2()
}
```

输出结果是

```
defer func:  0
defer func:  100
```

这是因为传递进f1中的参数i是形参，defer注册后，即使外面改变i也不会影响f1内部的参数了；f2输出100是因为defer中的i是全局变量，在外面改变时会影响到defer内的参数。

### level3

再来看这个level3的，test1()和test2()输出的结果一样吗？

```go

type message struct {
 content string
}

func (p *message) set(c string) {
 p.content = c
}

func (p *message) print1() string {
 //fmt.Println("print1 running")
 return p.content

}

func (p *message) print2() {
 //fmt.Println("print2 running")
 fmt.Println(p.content)

}

func test1() {
 m := &message{content: "Hello"}

 defer fmt.Println(m.print1())

 m.set("World")

 //fmt.Println("call print1")
}

func test2() {
 m := &message{content: "Hello"}

 defer m.print2()

 m.set("World")

 //fmt.Println("call print2")
}
```

结果是：test1输出`Hello`，test2输出`World`。可能test2输出`World`还好理解，因为相当于m中指向的内容被`m.set("World")`更改了;那么test1为什么输出`Hello`呢？这时因为defer调用print等输出函数时会先计算出实参结果，即使你后面再改变变量值对print也没有影响了。

## 底层实现
### defer
### panic
### recover

以上所有代码均在整理在[github go programming](https://github.com/meetbetter/go-programming)。
