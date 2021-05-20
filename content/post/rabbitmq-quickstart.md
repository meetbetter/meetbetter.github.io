---
title: "RabbitMQ 快速入门"
date: 2021-05-15T16:51:31+08:00
description: ""
draft: false
tags: [RabbitMQ]
---

介绍RabbitMQ的基础知识，和在电商系统中的使用场景。
<!--more-->


# 同步调用和异步通知

服务间通信通常使用RPC调用，是HTTP的请求和同步响应，RPC的优点是可以同步拿到想要的结果，系统设计简单，但是如果调用链路比较长，或者下游服务处理比较慢，就可能会导致调用方超时失败。

又比如通知类的消息，为了保证接收方一定能接收消息，使用RPC时可能需要在失败时重试几次，这也会增加链路的调用时间。

为了解决上述问题，我们可以使用消息队列（Message Queue），习惯简称MQ。

# 消息队列的应用场景

## 异步通知

在电商系统中，用户下单之后，订单系统除了正常记录订单状态外，还需要通过客户管理系统向卖家发送短信“有买家购买了您的菠萝蜜10000斤，订单号xxx，赶紧去发货吧！”，在使用同步调用的情况下，订单系统需要调用客户管理系统的发送短信接口，发送短信又需要依赖三方，大大增加了订单的处理时间，影响用户体验，极端情况下还会超时失败，图示如下：

![](https://cdn.jsdelivr.net/gh/meetbetter/cloudimg@main/img/20210516225135-RPC同步发送短信.png)

其实这种非核心流程的通知，可以借助MQ由同步调用改成异步通知，订单只负责生产消息发给MQ就返回，由客户管理系统异步地自己从MQ中读取消息避免因其他的系统处理时间过长造成接口响应慢甚至超时，图示如下：

![](https://cdn.jsdelivr.net/gh/meetbetter/cloudimg@main/img/20210516230126-MQ异步发送短信.png)

## 应用解耦

在许多时候，我们需要给其他系统发送通知，比如用户订单支付完成后，我们需要通知记账系统、客户管理系统等，使用RPC同步调用的图示如下：

![](https://cdn.jsdelivr.net/gh/meetbetter/cloudimg@main/img/20210516215320-RPC和MQ异步通知.png)

假如过几天，又有一个系统说我需要这个通知，支付系统就要修改代码，增加一个RPC，又过了一段时间客户管理系统说我不需要这个通知了，支付系统就要把删除给客户管理系统的RPC调用的代码，维护支付系统的同学可能要崩溃了。

支付系统和其他系统耦合太严重了，所以我们需要解耦，这个时候消息队列的优点就出来了，使用消息队列的发布-订阅模式，支付系统只需要把支付完成的消息写到消息队列中，后续谁想关注这个消息谁就订阅该消息，不需要时不订阅即可，和支付系统没关系了，图示如下：

![](https://cdn.jsdelivr.net/gh/meetbetter/cloudimg@main/img/20210516215824-RPC通知和MQ异步通知.png)

## 流量削峰

在记账系统中，经常存在热点账户，在并发量大时会降低系统的响应时间，比如大量用户同时购买商品支付完成后，都需要在同一个收款账户进行记账，为了保证账户增减的正确性，需要加锁操作，在并发量大时就会因锁竞争导致接口处理时间过长。图示如下：

![](https://cdn.jsdelivr.net/gh/meetbetter/cloudimg@main/img/20210516232718-RPC同步机长.png)

此时可以使用消息队列进行削峰，通过消息队列将并发的操作改成顺序执行，用户支付成功后支付系统将需要记账的消息发送给消息队列后直接返回，由记账系统从消息队列慢慢地消费消息进行异步记账，图示如下：

![](https://cdn.jsdelivr.net/gh/meetbetter/cloudimg@main/img/20210516233339-MQ异步记账.png)

# RabbitMQ介绍

AMQP（Advanced Message Queuing Protocol）是一个应用层标准高级消息队列协议，提供统一消息服务，RabbitMQ是使用Erlang实现AMQP的消息中间件，典型的生产者-消费者模型（producer-consumer）：

![](https://cdn.jsdelivr.net/gh/meetbetter/cloudimg@main/img/20210516234121-MQ生产者消费者模型.png)

## RabbitMQ内部结构

![](https://cdn.jsdelivr.net/gh/meetbetter/cloudimg@main/img/20210516234401-RabbitMQ内部结构.png)

Publisher：生产者，是发送消息的应用程序；

Broker：RabbitMQ消息队列的服务器；

Virtual Host：vhost，虚拟主机，一个RabbitMQ可以有多个虚拟主机，方便权限管理和按业务隔离；

Exchange：交换机，生产者通过交换机将消息发给对应的队列，交换机相当于一个路由表；

Queue：消息队列，存储消息的容器，消费者从消息队列中读取消息；

Binding：绑定关系，消息队列要通过一个key和交换机绑定，该key称为binding key;

Connection：应用程序和RabbitMQ之间的TCP连接；

Channel：管道，为了避免TCP建立和断开的开销而创建的虚拟管道，是对TCP连接的复用。

## RabbitMQ工作模式

RabbitMQ的工作模式取决于交换机的工作模式，交换机分为direct、topic、fanout、headers四种工作模式，不同工作模式分发消息的规则不同。其中headers是根据AMQP的header头来进行完全匹配，和direct作用一样但是性能差很多，平时很少使用。

### direct模式

完全匹配的单播模式，队列通过binding key和交换机绑定，生产者向交换机发送消息时携带routing key，只有bingding key和routing key完全匹配的队列才能收到消息。一个队列可以有多个消费者，如果有多个消费者连接同一个队列，也只能会有一个消费者接收到消息，如果想让多个消费者都能同时收到消息需要让多个消费者绑定到多个队列。

![](https://cdn.jsdelivr.net/gh/meetbetter/cloudimg@main/img/20210519211500-RabbitMQ-direct模式.png)

### topic模式

通配符模式，支持模糊匹配，生产者向交换机发送消息时携带routing key，只要bingding key和routing key部分匹配的队列就可以收到消息。使用.分割字符，#匹配0个或多个单词，*匹配不多不少一个单词。

![](https://cdn.jsdelivr.net/gh/meetbetter/cloudimg@main/img/20210519211722-RabbitMQ-topic模式.png)

### fanout模式

广播模式，每个发送到交换器的消息都会被转发到与该交换器绑定的所有队列上，性能最快。

![](https://cdn.jsdelivr.net/gh/meetbetter/cloudimg@main/img/20210519211815-RabbitMQ-fanout模式.png)

## 可靠性

评估消息队列好坏的最重要的点之一就是消息的可靠性，如何保证消息稳定不丢失，RabbitMQ通过支持持久化和消息确认机制保证了消息的稳定性，

### 持久性

交换机持久化：x为了防止在宕机时消息丢失，RabbitMQ支持交换机和队列的持久化，交换机持久化保证重启后交换机仍然存在；
队列持久化：队列的持久化保证重启后队列仍然存在；
消息持久化：保证重启后消息不丢失，消息持久化的前提是交换机和队列持久化。

### 消息确认

生产者confirm：为了避免生产者将消息发给RabbitMQ的过程中消息丢失，可以在发送时打开消息的confirm机制，在正确发送到队列后RabbitMQ会给生产者一个确认通知。

消费者手动ack：为了避免消费者从RabbitMQ读取消息处理过程中发生意外导致消息未被处理完成而消息已经被从队列中删除，RabbitMQ支持手动ack机制，只有消费者明确返回ack后才会从队列中删除消息。

为了保证幂等性，需要在消息内增加业务字段唯一字段，消费者据此保证业务幂等。

另外RabbitMQ还支持事务，但是会影响吞吐量。

### 平滑重启

除了RabbitMQ自带的可靠性保证，我们还需要考虑服务升级重启期间如果有正在处理消息的情况，如果此时直接结束进程，可能会导致部分消息未被处理完成。此时可以使用Linux signal机制保证服务的平滑重启，基本思路是代码中监听SIGKILL等特定signal，当收到signal后不立即结束进程，而是等待处理中的消息处理完成或者超时再退出，在此期间配合网关或k8s将新的请求分发到新服务，老的请求继续处理，实现平滑重启、优雅升级。
