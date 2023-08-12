# LanScanner

Using in Swift:

<h1><u> Import </u></h1>


```
import SwiftLanScanner
import Combine
```

<h1><u> Code </u></h1>

<b> Start, Stop Scan Device </b>

```
SwiftLanScanner.start()
SwiftLanScanner.stop()
```

<b> Get List Device In Lan </b>


```
SwiftLanScanner.listDevice.sink { list in
            list.forEach {
                print("IP: \($0.ipAddress ?? "") Brand: \($0.brand ?? "")")
            }
        }.store(in: &cancellable)
```


<b> Progress </b>


```
SwiftLanScanner.progress.sink { p in
            print("Progress: \(p)")
        }.store(in: &cancellable)

````

