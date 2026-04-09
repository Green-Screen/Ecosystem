# Ecosystem

## Current Version: V 2.1

Ecosystem is a FSM built for easy overall control ment to act as a manager
and dispatcher to control many different things specializing in AI

### **Make sure you set UseNewLuauTypeSolver to enabled in workspace properties to get proper intellisense**

### **Features:**

-   Single point sourced
-   Fully type annotated to support the luau type solver
-   built in signalling between species to communicate internally
-   static and server optimized
-   Dynamic

### **Changelog:**

-   Fixed StateFrom paramater not actually giving you the previous state.
-   Added experimental support of Stop method for closing a State from inside itself. (GC)
-   Added experimental State return of 'Stop' that is now registered to stop the state internally
-   Various performance and documentation additions

**_This module is still in testing and is not yet ready for production usage_**
