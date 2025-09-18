In AWS CloudFront, ordered_cache_behavior and default_cache_behavior are two types of cache behaviors that determine how content is cached and served by CloudFront. ordered_cache_behavior is used for specific paths or file types, while default_cache_behavior applies to all other requests that don't match a specific path in an ordered cache behavior. [1, 2, 3]  
Ordered Cache Behavior: [1, 2, 3]  

• Used to configure caching for specific paths or file types. 
• Allows for more granular control over caching, including setting specific TTLs, allowing or denying specific HTTP methods, and customizing cache keys. 
• Defined using a path_pattern argument. [1, 2, 3]  

Default Cache Behavior: [1]  

• Applies to all requests that don't match any of the path patterns in the ordered cache behaviors. 
• Has a simpler configuration than ordered cache behavior, but still allows for customizing caching parameters. 
• Does not have a path_pattern argument. [1]  

In essence: [1, 2, 3]  

• ordered_cache_behavior provides more fine-grained control over caching for specific content, while default_cache_behavior serves as the "catch-all" for everything else. 
• You can use both in a distribution, with ordered_cache_behavior addressing specific content and default_cache_behavior handling the rest. [1, 2, 3]  

Generative AI is experimental.

[1] https://www.stream.security/resources/cloudfront[2] https://stackoverflow.com/questions/59493540/what-is-prefetchsize-in-rabbitmq[3] https://forum.djangoproject.com/t/prefetch-related-objects-how-to-use-how-to-work/34173
