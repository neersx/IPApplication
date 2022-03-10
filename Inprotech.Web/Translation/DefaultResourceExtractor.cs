using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure;

namespace Inprotech.Web.Translation
{
    public interface IDefaultResourceExtractor
    {
        Task<IEnumerable<TranslatableItem>> Extract();
    }

    public class DefaultResourceExtractor : IDefaultResourceExtractor
    {
        readonly IResourceFile _resourceFile;

        public DefaultResourceExtractor(IResourceFile resourceFile)
        {
            if (resourceFile == null) throw new ArgumentNullException("resourceFile");
            _resourceFile = resourceFile;
        }

        public async Task<IEnumerable<TranslatableItem>> Extract()
        {
            var contents = await _resourceFile.ReadAsync(KnownPaths.Translations);

            return JsonUtility.FlattenHierarchy(contents)
                              .Select(_ => new TranslatableItem
                                           {
                                               Source = "condor",
                                               Area = _.Key.CondorAppSourceKey(),
                                               ResourceKey = _.Key,
                                               Default = _.Value
                                           });
        }
    }
}