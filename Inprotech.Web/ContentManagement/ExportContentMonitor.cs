using System;
using System.Linq;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Messaging;
using Inprotech.Web.Messaging;
using InprotechKaizen.Model.Components.ContentManagement.Export;
using InprotechKaizen.Model.Components.System.Messages;

namespace Inprotech.Web.ContentManagement
{
    public interface IExportContentMonitor : IMonitorClockRunnable
    {
    }

    public class ExportContentMonitor : IExportContentMonitor
    {
        readonly IBus _bus;
        readonly IClientSubscriptions _clientSubscriptions;
        readonly IExportContentStatusReader _exportContentStatusReader;
        readonly IExportContentDataProvider _exportContentDataProvider;
        const string SearchExportContentTopic = "export.content";

        public ExportContentMonitor(IBus bus, IClientSubscriptions clientSubscriptions,
                                                    IExportContentStatusReader exportContentStatusReader,
                                                    IExportContentDataProvider exportContentContentIdProvider)
        {
            _bus = bus;
            _clientSubscriptions = clientSubscriptions;
            _exportContentStatusReader = exportContentStatusReader;
            _exportContentDataProvider = exportContentContentIdProvider;
        }
        
        public void Run()
        {
            var connections = _clientSubscriptions
                .Find(SearchExportContentTopic, (a, b) => string.Equals(a, b, StringComparison.OrdinalIgnoreCase)).ToArray();
            if (!connections.Any()) return;

            var results = _exportContentStatusReader.ReadMany(connections).ToArray();
            if (!results.Any()) return;
            
            foreach (var result in results)
            {
                if (!result.ContentList.Any() || PreventPublishingSameData(result)) continue;

                _bus.Publish(new SendMessageToClient
                {
                    ConnectionId = result.ConnectionId,
                    Topic = SearchExportContentTopic,
                    Data = result.ContentList
                });
            }
        }

        bool PreventPublishingSameData(ExportContent exportContent)
        {
            _exportContentDataProvider.PublishedData
                                     .TryGetValue(exportContent.ConnectionId, out var exportContentData);

            if (exportContentData != null
                    && exportContentData.Count == exportContent.ContentList.Count
                    && !exportContentData.Except(exportContent.ContentList, new ExportContentDataComparer()).Any())
            {
                return true;
            }

            _exportContentDataProvider.PublishedData
                                     .AddOrUpdate(exportContent.ConnectionId, exportContent.ContentList,
                                                  (key, value) => value);
            return false;
        }
    }
}
