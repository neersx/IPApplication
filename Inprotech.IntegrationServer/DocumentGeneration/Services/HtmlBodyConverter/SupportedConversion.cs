using System;
using System.Collections.Generic;
using System.IO;

namespace Inprotech.IntegrationServer.DocumentGeneration.Services.HtmlBodyConverter
{
    public class CategoryResolver
    {
        static readonly Dictionary<string, Category> Map =
            new Dictionary<string, Category>(StringComparer.InvariantCultureIgnoreCase)
            {
                {"docx", Category.Word},
                {"doc", Category.Word},
                {"docm", Category.Word},
                {"dotx", Category.Word},
                {"dotm", Category.Word},
            };

        public static Category Resolve(string path)
        {
            if (path == null) throw new ArgumentNullException(nameof(path));

            var extension = Path.GetExtension(path).ToLower().TrimStart('.');

            if (Map.TryGetValue(extension, out Category value))
                return value;

            return Category.Unknown;
        }
    }

    public enum Category
    {
        Unknown,
        Word
    }
}