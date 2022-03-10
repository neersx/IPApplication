using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading.Tasks;

namespace Inprotech.StorageService.Storage
{
    public interface IRecursivelySearchForPathInCache
    {
        Task<FilePathModel> RecursivelySearchInCache(string folderPath, IEnumerable<FilePathModel> topLevelNodes);
    }

    public class RecursivelySearchForPathInCache : IRecursivelySearchForPathInCache
    {
        public async Task<FilePathModel> RecursivelySearchInCache(string folderPath, IEnumerable<FilePathModel> topLevelNodes)
        {
            var isNetworkPath = folderPath.StartsWith($"{Path.DirectorySeparatorChar}{Path.DirectorySeparatorChar}");
            var tokens = folderPath.Split(Path.DirectorySeparatorChar).Where(_ => !string.IsNullOrWhiteSpace(_)).ToArray();
            var networkToken = isNetworkPath ? $"{Path.DirectorySeparatorChar}{Path.DirectorySeparatorChar}" : string.Empty;
            var tokenFirst = $"{networkToken}{tokens[0]}{Path.DirectorySeparatorChar}";
            tokenFirst += tokens.Length > 1 ? $"{tokens[1]}{Path.DirectorySeparatorChar}" : string.Empty;
            FilePathModel topFolder = null;
            int index;
            for (index = 0; index < tokens.Length && topFolder == null; index++)
            {
                var tokensLength = tokens.Length - index;
                var prefix = isNetworkPath ? $"{Path.DirectorySeparatorChar}{Path.DirectorySeparatorChar}" : string.Empty;
                var testTokens = prefix + string.Join(Path.DirectorySeparatorChar.ToString(), tokens.Take(tokensLength).ToList()) + Path.DirectorySeparatorChar;
                topFolder = topLevelNodes.FirstOrDefault(_ => string.Equals(_.Path, testTokens, StringComparison.InvariantCultureIgnoreCase));
                if (topFolder != null)
                {
                    tokenFirst = testTokens;
                }
            }

            tokens = tokens.Skip(tokens.Length - index + 1).ToArray();
            while (tokens.Any() && topFolder != null)
            {
                tokenFirst = $"{tokenFirst}{tokens.First()}{Path.DirectorySeparatorChar}";
                topFolder = topFolder.SubFolders.FirstOrDefault(_ => _.Path == tokenFirst);
                tokens = tokens.Skip(1).ToArray();
            }

            return topFolder;
        }
    }
}