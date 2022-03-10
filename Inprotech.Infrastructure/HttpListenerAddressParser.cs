using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;

namespace Inprotech.Infrastructure
{
    public static class HttpListenerAddressParser
    {
        public static string[] Parse(string bindingUrls, string parentPath, string paths)
        {
            if(string.IsNullOrWhiteSpace(bindingUrls)) throw new ArgumentException("A valid bindingUrls is required.");

            return (from a in Split(bindingUrls)
                    from b in Split(paths)
                    select CombineUrls(a, parentPath, b))
                .ToArray();
        }

        static IEnumerable<string> Split(string input)
        {
            return
                input.Split(new[] {','}, StringSplitOptions.RemoveEmptyEntries)
                     .Where(e => !String.IsNullOrWhiteSpace(e));
        }

        static string CombineUrls(params string[] urls)
        {
            return Path.Combine(urls.Select(u => u.Trim(new []
                                                        {
                                                            ' ', '/', '\\'
                                                        })).ToArray())
                       .Replace('\\', '/');
        }
    }
}