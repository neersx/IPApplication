using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Extensions;
using InprotechKaizen.Model.Configuration.SiteControl;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Configuration.SiteControl
{
    public interface ICachedSiteControl : ISiteControlDataTypeFormattable
    {
        string Id { get; }
    }

    internal class InterimSiteControl : ICachedSiteControl
    {
        public string Id { get; set; }

        public string DataType { get; set; }

        public int? IntegerValue { get; set; }

        public string StringValue { get; set; }

        public bool? BooleanValue { get; set; }

        public decimal? DecimalValue { get; set; }

        public DateTime? DateValue { get; set; }

        public string InitialValue { get; }
    }

    public class SiteControlReader : ISiteControlReader
    {
        readonly IDbContext _dbContext;
        readonly ISiteControlCache _siteControlCache;

        public SiteControlReader(IDbContext dbContext, ISiteControlCache siteControlCache)
        {
            _dbContext = dbContext;
            _siteControlCache = siteControlCache;
        }

        public T Read<T>(string name)
        {
            return ReadMany<T>(name).Get(name);
        }

        public Dictionary<string, T> ReadMany<T>(params string[] names)
        {
            return _siteControlCache.Resolve(r => from sc in _dbContext.Set<Model.Configuration.SiteControl.SiteControl>()
                                                  where r.Contains(sc.ControlId)
                                                  select new InterimSiteControl
                                                  {
                                                      Id = sc.ControlId,
                                                      DataType = sc.DataType,
                                                      IntegerValue = sc.IntegerValue,
                                                      StringValue = sc.StringValue,
                                                      BooleanValue = sc.BooleanValue,
                                                      DecimalValue = sc.DecimalValue,
                                                      DateValue = sc.DateValue
                                                  }, names)
                                    .ToDictionary(x => x.Id, v => (T) ConvertSiteControlValue(typeof(T), v), StringComparer.InvariantCultureIgnoreCase);
        }

        static object ConvertSiteControlValue(Type type, ISiteControlDataTypeFormattable siteControl)
        {
            if (type == typeof(int?))
            {
                return siteControl.IntegerValue;
            }

            if (type == typeof(bool?))
            {
                return siteControl.BooleanValue;
            }

            if (type == typeof(DateTime?))
            {
                return siteControl.DateValue;
            }

            if (type == typeof(decimal?))
            {
                return siteControl.DecimalValue;
            }

            if (type == typeof(string))
            {
                return siteControl.StringValue;
            }

            if (type == typeof(int))
            {
                return siteControl.IntegerValue ?? 0;
            }

            if (type == typeof(decimal))
            {
                return siteControl.DecimalValue ?? 0;
            }

            if (type == typeof(bool))
            {
                return siteControl.BooleanValue ?? false;
            }

            throw new ArgumentOutOfRangeException($"Could not find a matching site control value for type: {type}");
        }
    }
}