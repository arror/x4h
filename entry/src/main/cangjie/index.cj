package interop

import ohos.ark_interop.*
import ohos.ark_interop_macro.*
import std.collection.concurrent.*

foreign func GoInvoke(service: CString, parameters: CString): CString
foreign func GoFreeCString(string: CString): Unit

public class TaskScheduler {

    private let iQueue: LinkedBlockingQueue<(String, String)>
    private let oQueue: LinkedBlockingQueue<String>

    public static let shared = TaskScheduler()

    private init() {
        this.iQueue = LinkedBlockingQueue<(String, String)>(1)
        this.oQueue = LinkedBlockingQueue<String>(1)
        spawn {
        	while (true) {
        		let (service, parameters) = iQueue.remove()
                let result = this.impl(service, parameters)
                this.oQueue.add(result)
        	}
        }
    }

    public func invoke(service: String, parameters: String): String {
        this.iQueue.add((service, parameters))
        return this.oQueue.remove()
    }

    private func impl(service: String, parameters: String): String {
        return unsafe {
            let arg1 = LibC.mallocCString(service)
            let arg2 = LibC.mallocCString(parameters)
            let value = GoInvoke(arg1, arg2)
            let result = value.toString()
            LibC.free(arg1)
            LibC.free(arg2)
            GoFreeCString(value)
            return result
        }
    }
}


@Interop[ArkTS]
public func Invoke(service: String, parameters: String): String {
    return TaskScheduler.shared.invoke(service, parameters)
}

