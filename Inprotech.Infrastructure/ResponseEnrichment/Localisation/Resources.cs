using System.Collections.Generic;
using System.IO;

namespace Inprotech.Infrastructure.ResponseEnrichment.Localisation
{
    public interface IResources
    {
        IEnumerable<Resource> Resolve(string resource, string fallbackResource);
    }

    public class Resources : IResources
    {
        const string PathTemplate = "condor/localisation/translations/translations_{0}.json";

        const string BasePath = "client";
        readonly IFileHelpers _fileHelpers;

        public Resources(IFileHelpers fileHelpers)
        {
            _fileHelpers = fileHelpers;
        }

        public IEnumerable<Resource> Resolve(string resource, string fallbackResource)
        {
            string path;

            if (!string.IsNullOrWhiteSpace(fallbackResource))
            {
                path = string.Format(PathTemplate, fallbackResource);
                if (_fileHelpers.Exists(Path.Combine(BasePath, path)))
                {
                    yield return new Resource
                    {
                        Code = fallbackResource,
                        Path = path
                    };
                }
            }

            if (!string.IsNullOrWhiteSpace(resource))
            {
                path = string.Format(PathTemplate, resource);
                if (_fileHelpers.Exists(Path.Combine(BasePath, path)))
                {
                    yield return new Resource
                    {
                        Code = resource,
                        Path = path
                    };
                }
            }
        }
    }

    public class Resource
    {
        public string Code { get; set; }

        public string Path { get; set; }
    }
}