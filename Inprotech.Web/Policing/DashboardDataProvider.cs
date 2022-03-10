using System;
using System.Collections.Generic;
using InprotechKaizen.Model.Components.Policing;
using InprotechKaizen.Model.Components.Policing.Monitoring;
using InprotechKaizen.Model.Policing;

namespace Inprotech.Web.Policing
{
    public enum RetrieveOption
    {
        Default,
        WithTrends
    }

    public interface IDashboardDataProvider
    {
        Dictionary<RetrieveOption, DashboardData> Retrieve(RetrieveOption option = RetrieveOption.WithTrends);
    }

    public class DashboardDataProvider : IDashboardDataProvider
    {
        readonly ISummaryReader _summaryReader;
        readonly ILogReader _logReader;

        public DashboardDataProvider(ISummaryReader summaryReader, ILogReader logReader)
        {
            if (summaryReader == null) throw new ArgumentNullException("summaryReader");
            if (logReader == null) throw new ArgumentNullException("logReader");

            _summaryReader = summaryReader;
            _logReader = logReader;
        }

        public Dictionary<RetrieveOption, DashboardData> Retrieve(RetrieveOption option = RetrieveOption.WithTrends)
        {
            var summary = _summaryReader.Read();
            var historialData = option == RetrieveOption.WithTrends && _logReader.IsHistoricalDataAvailable();
            var rateGraphItems = new PolicingRateItem[0];
            var hasError = false;

            if (historialData)
            {
                if (!_logReader.TryGetRateGraphData(out rateGraphItems))
                    hasError = true;
            }

            return new Dictionary<RetrieveOption, DashboardData>
                   {
                       {
                           RetrieveOption.Default, new DashboardData
                                                   {
                                                       Summary = summary,
                                                       Trend = new
                                                               {
                                                                   HistoricalDataAvailable = false,
                                                                   HasError = false,
                                                                   Items = new PolicingRateItem[0]
                                                               }
                                                   }
                       },
                       {
                           RetrieveOption.WithTrends, new DashboardData
                                                      {
                                                          Summary = summary,
                                                          Trend = new
                                                                  {
                                                                      HistoricalDataAvailable = historialData,
                                                                      HasError = hasError,
                                                                      Items = rateGraphItems
                                                                  }
                                                      }
                       }
                   };
        }
    }

    public class DashboardData
    {
        public Summary Summary { get; set; }

        public dynamic Trend { get; set; }
    }

    public static class DashboardDataExtension
    {
        public static dynamic AsViewData(this Dictionary<RetrieveOption, DashboardData> data)
        {
            return data[RetrieveOption.WithTrends];
        }

        public static Summary SummaryOnly(this Dictionary<RetrieveOption, DashboardData> data)
        {
            return data[RetrieveOption.Default].Summary;
        }
    }
}