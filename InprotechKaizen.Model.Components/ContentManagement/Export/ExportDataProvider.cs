using System.Collections.Concurrent;
using System.Collections.Generic;

namespace InprotechKaizen.Model.Components.ContentManagement.Export
{
    public interface IExportContentDataProvider
    {
        ConcurrentDictionary<string, List<ExportContentData>> PublishedData { get; }
    }

    public class ExportContentDataProvider : IExportContentDataProvider
    {
        public ConcurrentDictionary<string, List<ExportContentData>> PublishedData { get; } = new();
    }
}