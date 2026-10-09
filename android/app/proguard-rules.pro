# kotlinx.serialization keeps its generated serializers by name.
-keepattributes *Annotation*, InnerClasses
-dontnote kotlinx.serialization.AnnotationsKt
-keepclassmembers class kotlinx.serialization.json.** { *** Companion; }
-keepclasseswithmembers class kotlinx.serialization.json.** { kotlinx.serialization.KSerializer serializer(...); }
-keep,includedescriptorclasses class com.wickedstudios.wonderlot.**$$serializer { *; }
-keepclassmembers class com.wickedstudios.wonderlot.** { *** Companion; }
-keepclasseswithmembers class com.wickedstudios.wonderlot.** { kotlinx.serialization.KSerializer serializer(...); }
