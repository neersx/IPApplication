using System;
using System.Linq;
using System.Text;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Extensions;
using InprotechKaizen.Model.Configuration.SiteControl;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.System.Policy.AuditTrails
{
    public class ContextInfoSerializer : IContextInfoSerializer
    {
        const string HexFormat = "{0:x8}";
        readonly IDbContext _dbContext;
        
        public ContextInfoSerializer(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public byte[] SerializeContextInfo(int userId, int? transactionInfoId = null, int? batchId = null, int? componentId = null)
        {
            var siteControls = (from sc in _dbContext.Set<SiteControl>()
                                where sc.ControlId == SiteControls.LogTimeOffset || sc.ControlId == SiteControls.OfficeForReplication
                                select new
                                {
                                    sc.ControlId,
                                    sc.IntegerValue
                                }).ToDictionary(k => k.ControlId, v => v.IntegerValue);

            var contextInfo = new StringBuilder();
            
            contextInfo.Append(string.Format(HexFormat, userId));

            contextInfo.Append(string.Format(HexFormat, transactionInfoId ?? 0));
            
            contextInfo.Append(string.Format(HexFormat, batchId ?? 0));

            contextInfo.Append(string.Format(HexFormat, siteControls.Get(SiteControls.OfficeForReplication) ?? 0));

            contextInfo.Append(string.Format(HexFormat, siteControls.Get(SiteControls.LogTimeOffset) ?? 0));

            contextInfo.Append(string.Format(HexFormat, componentId ?? 0));

            return Enumerable.Range(0, contextInfo.ToString().Length)
                             .Where(x => x % 2 == 0)
                             .Select(x => Convert.ToByte(contextInfo.ToString().Substring(x, 2), 16))
                             .ToArray();
        }
    }
}