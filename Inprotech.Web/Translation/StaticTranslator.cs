using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Localisation;

namespace Inprotech.Web.Translation
{
    public class StaticTranslator : IStaticTranslator, IDisposable
    {
        const string FilePattern = "translations_*.json";
        Dictionary<string, Dictionary<string, string>> _data;
        readonly string _dataDirectory;
        readonly FileSystemWatcher _watcher;
        
        public event EventHandler<EventArgs> Reloaded;

        public StaticTranslator(string dataDirectory)
        {
            _dataDirectory = dataDirectory;
            _watcher = new FileSystemWatcher(dataDirectory)
                           {
                               NotifyFilter = NotifyFilters.LastWrite | NotifyFilters.FileName | NotifyFilters.DirectoryName,
                               EnableRaisingEvents = true,
                               Filter = FilePattern
                           };

            _watcher.Changed += (sender, args) => Reload();
            _watcher.Deleted += (sender, args) => Reload();

            Reload();
        }

        public string Translate(string original, IEnumerable<string> acceptableCultures)
        {
            foreach (var culture in acceptableCultures)
            {
                Dictionary<string, string> cultureData;

                if (_data.TryGetValue(culture, out cultureData))
                {
                    string translation;

                    if (cultureData.TryGetValue(original, out translation)) return translation;
                }
            }
            return original;
        }

        public string TranslateWithDefault(string original, IEnumerable<string> acceptableCultures)
        {
            var enumerable = acceptableCultures.ToList();
            if(!enumerable.Any(_=> _.Contains("en")))
                enumerable.Add("en");
            
            return Translate(original, enumerable);
        }
        void Reload()
        {
            var newData = new Dictionary<string, Dictionary<string, string>>();

            foreach (var file in new DirectoryInfo(_dataDirectory).GetFiles(FilePattern))
            {
                try
                {
                    var json = File.ReadAllText(file.FullName);
                    var flat = JsonUtility.FlattenHierarchy(json);
                    
                    var cultureKey = Wildcard.Match(file.Name, FilePattern, true);
                    if (string.IsNullOrEmpty(cultureKey)) throw new Exception("cannot extract culture name from file name " + file.Name);

                    newData[cultureKey] = flat;
                }
                catch
                {
                    // users can manually change files while the service is runnign
                    // if any problem occurs we don't want to crash the service
                }
            }

            _data = newData;
            Reloaded?.Invoke(this, null);
        }

        void Dispose(bool disposing)
        {
            if (disposing)
            {
                _watcher?.Dispose();
            }
        }

        public void Dispose()
        {
            Dispose(true);
            GC.SuppressFinalize(this);
        }

        ~StaticTranslator()
        {
            Dispose(false);
        }
    }
}
