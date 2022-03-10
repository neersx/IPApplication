using System;
using System.Collections.Concurrent;

namespace Inprotech.Integration.DocumentGeneration
{
    public interface IPdfDocumentCache
    {
        CachedDocument Retrieve(string key);
        CachedDocument RetrieveAndDelete(string key);
        string CacheDocument(CachedDocument document);
    }

    public class PdfDocumentCache : IPdfDocumentCache
    {
        readonly ConcurrentDictionary<string, CachedDocument> _cache;

        public PdfDocumentCache()
        {
            _cache = new ConcurrentDictionary<string, CachedDocument>();
        }

        public string CacheDocument(CachedDocument document)
        {
            var key = Guid.NewGuid().ToString();
            if (_cache.TryAdd(key, document)) return key;

            return string.Empty;
        }

        public CachedDocument Retrieve(string key)
        {
            return _cache.TryGetValue(key, out var documentBytes) ? documentBytes : null;
        }

        public CachedDocument RetrieveAndDelete(string key)
        {
            return _cache.TryRemove(key, out var documentBytesRemove) ? documentBytesRemove : null;
        }
    }

    public class CachedDocument
    {
        public byte[] Data { get; set; }
        public string FileName { get; set; }
    }
}