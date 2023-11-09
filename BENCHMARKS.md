# Benchmarks

## Disclaimer

Benchmarking is notoriously difficult so I probably messed something up!

## Methodology

I was interested if redbean/fullmoon/lua would be able to come close to matching the performance of the JVM.

Since redbean only supports sqlite and the default spring petclinic database is in memory H2, I decided to test the front page
of the application since that doesn't have any database interaction. So mainly we are testing the performance of the web server and the templating engine.

I used wrk to run the load tests

https://github.com/wg/wrk

My machine is an Intel Core i7-6700 with 16 GB RAM, an SSD and running Linux Mint 21

Redbean command line: ```/${REDBEAN} -s -d -P ${PROJECT}.pid```

Redbean benchmark command line: ```wrk --latency -t 1000 -c 1000 --timeout 5s -H 'Accept-Encoding: gzip' http://127.0.0.1:8000/```

Java command line: ```java -jar -server -Xms1024M -Xmx1024M spring-petclinic-3.1.0-SNAPSHOT.jar```

Java benchmark command line: ```wrk --latency -t 1000 -c 1000 --timeout 5s -H 'Accept-Encoding: gzip' http://127.0.0.1:8080/```

* Note that I ran the Java benchmark twice to allow the JVM to warm up and then ran it again to get results

## Results

### Redbean (3 runs)
wrk --latency -t 1000 -c 1000 --timeout 5s -H 'Accept-Encoding: gzip' http://127.0.0.1:8000/
Running 10s test @ http://127.0.0.1:8000/
  1000 threads and 1000 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency   106.50ms  169.35ms   3.87s    86.26%
    Req/Sec    41.71     42.55     1.93k    88.52%
  Latency Distribution
     50%    1.62ms
     75%  183.48ms
     90%  315.49ms
     99%  514.39ms
  281803 requests in 10.11s, 409.84MB read
  Socket errors: connect 0, read 0, write 0, timeout 42
Requests/sec:  27881.14
Transfer/sec:     40.55MB

wrk --latency -t 1000 -c 1000 --timeout 5s -H 'Accept-Encoding: gzip' http://127.0.0.1:8000/
Running 10s test @ http://127.0.0.1:8000/
  1000 threads and 1000 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency   110.45ms  207.81ms   3.90s    90.45%
    Req/Sec    40.67     40.99     1.07k    89.69%
  Latency Distribution
     50%    1.45ms
     75%  182.31ms
     90%  312.91ms
     99%  541.05ms
  273080 requests in 10.11s, 397.15MB read
  Socket errors: connect 0, read 0, write 0, timeout 52
Requests/sec:  27015.94
Transfer/sec:     39.29MB

wrk --latency -t 1000 -c 1000 --timeout 5s -H 'Accept-Encoding: gzip' http://127.0.0.1:8000/
Running 10s test @ http://127.0.0.1:8000/
  1000 threads and 1000 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency   125.36ms  170.34ms   2.90s    84.11%
    Req/Sec    37.36     37.19     1.99k    86.65%
  Latency Distribution
     50%   56.64ms
     75%  219.46ms
     90%  356.36ms
     99%  542.74ms
  308412 requests in 10.11s, 448.54MB read
  Socket errors: connect 0, read 0, write 0, timeout 66
Requests/sec:  30505.44
Transfer/sec:     44.37MB


### Java (3 runs after 2 warmup runs)
Running 10s test @ http://127.0.0.1:8080/
  1000 threads and 1000 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency    69.50ms   84.46ms 754.90ms   85.91%
    Req/Sec    32.52     64.97     1.33k    88.56%
  Latency Distribution
     50%   48.04ms
     75%  112.57ms
     90%  180.41ms
     99%  362.76ms
  286999 requests in 10.11s, 832.24MB read
Requests/sec:  28392.33
Transfer/sec:     82.33MB

wrk --latency -t 1000 -c 1000 --timeout 5s -H 'Accept-Encoding: gzip' http://127.0.0.1:8080/
Running 10s test @ http://127.0.0.1:8080/
  1000 threads and 1000 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency    87.98ms  128.26ms   1.02s    88.30%
    Req/Sec    37.56     71.73     1.06k    86.96%
  Latency Distribution
     50%   45.94ms
     75%  128.64ms
     90%  237.60ms
     99%  627.21ms
  278886 requests in 10.11s, 808.83MB read
Requests/sec:  27587.16
Transfer/sec:     80.01MB

wrk --latency -t 1000 -c 1000 --timeout 5s -H 'Accept-Encoding: gzip' http://127.0.0.1:8080/
Running 10s test @ http://127.0.0.1:8080/
  1000 threads and 1000 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency   103.91ms  148.86ms 990.90ms   86.61%
    Req/Sec    41.04     74.84     1.36k    86.16%
  Latency Distribution
     50%   48.12ms
     75%  146.29ms
     90%  313.01ms
     99%  639.46ms
  288249 requests in 10.11s, 835.92MB read
Requests/sec:  28522.23
Transfer/sec:     82.71MB

### Summary (avg of 3 runs)

| Server     | Requests/sec | Avg latency | Std Dev latency | Timeouts | 
| ----------- | ----------- | ----------- | ----------- | ----------- |
| Redbean    | 28467       | 114        | 182        |  53        |
| JVM        | 28167      | 87          | 120        |  0         |


* Pre warmup - the JVM performs much worse - (3k requests/sec with latency of 700 ms)