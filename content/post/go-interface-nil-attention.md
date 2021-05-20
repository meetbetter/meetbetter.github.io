---
title: "踩坑记录：nil对象转换成interface不是nil"
date: 2020-08-30T23:03:59+08:00
description: ""
draft: false
tags: [golang]
---



<!--more-->

最近在项目中踩了一个深坑——“nil对象转换成interface不是nil"，现象是函数内返回了nil给一个对象，使用interface接收函数返回值判断始终不为nil。总结下分享出来，如果你不是很理解这句话，那推荐认真看下下面的示例代码，避免以后写代码时踩坑。

## 示例一

先一起来看下这段代码，你感觉有没有问题呢？

```go
type IPeople interface {
 hello()
}
type People struct {
}

func (p *People) hello() {
 fmt.Println("github.com/meetbetter")
}

func errFunc1(in int) *People {
 if in == 0 {
  fmt.Println("importantFunc返回了一个nil")
  return nil
 } else {
  fmt.Println("importantFunc返回了一个非nil值")
  return &People{}
 }

}

func main() {
 var i IPeople

 in := 0

 i = errFunc1(in)

 if i == nil {

  fmt.Println("哈，外部接收到也是nil")
 } else {

  fmt.Println("咦，外部接收到不是nil哦")
  fmt.Printf("%v, %T\n", i, i)
 }

}
```

这段代码的执行结果是:

```shell
importantFunc返回了一个nil
咦，外部接收到不是nil哦
<nil>, *main.People
```

可以看到在main函数中收到的返回值不是nil， 明明在errFunc1()函数中返回的是nil，到了main函数为什么收到的不是nil呢？
这是因为：将nil赋值给`*People`后再将`*People`赋值给interface，`*People`本身是是个指向nil的指针，但是将其赋给接口时只是接口中的值为nil，但是接口中的类型信息为`*main.People`而不是nil，所以这个接口不是nil。
是的，Golang中的interface类型包含两部分信息：type和value，只有interface的值和类型都为nil时interface才为nil，interface底层实现可以在后面的源码分析看到。

先来看看正确的处理接口返回值的方法，是直接将nil赋给interface：

```go

func rightFunc(in int) IPeople {
 if in == 0 {
  fmt.Println("importantFunc返回了一个nil")
  return nil
 } else {
  fmt.Println("importantFunc返回了一个非nil值")
  return &People{}
 }

}
```

## 示例二

下面的代码更清晰的证明了`一个包含nil指针的接口不是nil接口`的结论：

```go
type IPeople interface {
 hello()
}
type People struct {
}

func (p *People) hello() {
 fmt.Println("github.com/meetbetter")
}

//错误：将nil的people给空接口后接口就不为nil,因为interface中的value为nil但type不为nil

func errFunc() *People {

 return nil
}

//正确处理返回nil给接口的方法,返回时go就确定了接口是不是nil
func rightFunc() IPeople {

 return nil
}
func main() {

 var i IPeople
 i = errFunc()
 if i == nil { //想通过接口是否为nil来判断故障，却始终判断接口非空

  fmt.Println("errFunc对了哦，外部接收到也是nil")
  fmt.Println(reflect.TypeOf(i))
 } else {

  fmt.Println("errFunc错了咦，外部接收到不是nil哦")
  fmt.Println(reflect.TypeOf(i))
 }

 i = rightFunc()
 if i == nil {

  fmt.Println("rightFunc对了哦，外部接收到也是nil")
  fmt.Println(reflect.TypeOf(i))
 } else {

  fmt.Println("rightFunc错了咦，外部接收到不是nil哦")
  fmt.Println(reflect.TypeOf(i))

 }

}
```

输出结果：

```shell
errFunc错了咦，外部接收到不是nil哦
*main.People
rightFunc对了哦，外部接收到也是nil
<nil>
```

## interface底层实现
Go中，空接口底层结构为eface，普通接口底层为iface。
下面的注释信息来自参考文章中，从interface底层实现可以看出iface比eface 中间多了一层itab结构， itab 存储_type信息和[]fun方法集，所以即使data指向了nil 并不代表interface 就是nil， 还要考虑_type信息。

```go
type eface struct {      //空接口
    _type *_type         //类型信息
    data  unsafe.Pointer //指向数据的指针(go语言中特殊的指针类型unsafe.Pointer类似于c语言中的void*)
}
type iface struct {      //带有方法的接口
    tab  *itab           //存储type信息还有结构实现方法的集合
    data unsafe.Pointer  //指向数据的指针(go语言中特殊的指针类型unsafe.Pointer类似于c语言中的void*)
}
type _type struct {
    size       uintptr  //类型大小
    ptrdata    uintptr  //前缀持有所有指针的内存大小
    hash       uint32   //数据hash值
    tflag      tflag
    align      uint8    //对齐
    fieldalign uint8    //嵌入结构体时的对齐
    kind       uint8    //kind 有些枚举值kind等于0是无效的
    alg        *typeAlg //函数指针数组，类型实现的所有方法
    gcdata    *byte
    str       nameOff
    ptrToThis typeOff
}
type itab struct {
    inter  *interfacetype  //接口类型
    _type  *_type          //结构类型
    link   *itab
    bad    int32
    inhash int32
    fun    [1]uintptr      //可变大小 方法集合
}
```

以上完整代码均整理在[Github-跟着示例代码学Golang项目](https://github.com/meetbetter/learn-golang/tree/master/02_advance/11_nil-interface)。

参考文章：

[Golang第一大坑](https://studygolang.com/articles/10635)

["一个包含nil指针的接口不是nil接口"的讨论](https://gocn.vip/question/1011)
