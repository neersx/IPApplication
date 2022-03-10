using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Accounting.Billing.Generation
{
    public interface IBillPrintDetails
    {
        Task<IEnumerable<BillPrintDetail>> For(int userIdentityId, string culture, int itemEntityId, string openItemNo, bool shouldPrintAsOriginal);
    }

    public class BillPrintDetails : IBillPrintDetails
    {
        /// <summary>
        /// Reporting Service - Report Definition Language file 
        /// </summary>
        const string Rdl = ".rdl";

        /// <summary>
        /// Centura Report Builder file
        /// </summary>
        const string Qrp = ".qrp";

        static string[] _availableFields;

        readonly IDbContext _dbContext;

        public BillPrintDetails(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public async Task<IEnumerable<BillPrintDetail>> For(int userIdentityId, string culture, int itemEntityId, string openItemNo, bool shouldPrintAsOriginal)
        {
            var billPrintDetails = new List<BillPrintDetail>();

            using var sp = _dbContext.CreateStoredProcedureCommand("biw_GetInvoicePrintDetails", new Parameters
            {
                {"@pnUserIdentityId", userIdentityId },
                {"@psCulture", culture},
                {"@pnEntityNo", itemEntityId},
                {"@psOpenItemNo", openItemNo},
                {"@pbPrintAsOriginal", shouldPrintAsOriginal}
            });

            using var reader = await sp.ExecuteReaderAsync();

            while (await reader.ReadAsync())
            {
                _availableFields ??= Enumerable.Range(0, reader.FieldCount)
                                               .Select(i => reader.GetName(i))
                                               .ToArray();
                
                billPrintDetails.Add(new BillPrintDetail
                {
                    CopyNo = reader.GetField<int>("CopyNo"),
                    OpenItemNo = reader.GetField<string>("OpenItemNo"),
                    EntityCode = reader.GetField<string>("EntityCode"),
                    BillPrintType = DerivePrintType(reader.GetField<string>("BillPrintType")),
                    BillTemplate = StripTemplateExtension(reader.GetField<string>("BillTemplate")),
                    ReprintLabel = reader.GetField<string>("ReprintLabel"),
                    CopyLabel = reader.GetField<string>("CopyLabel"),
                    CopyToName = reader.GetField<string>("CopyToName"),
                    CopyToAttention = reader.GetField<string>("CopyToAttention"),
                    CopyToAddress = reader.GetField<string>("CopyToAddress"),
                    IsPdfModifiable = !_availableFields.Contains("ModifiablePdf") || reader.GetField<bool>("ModifiablePdf")
                });
            }

            return billPrintDetails;
        }
        
        static BillPrintType DerivePrintType(string printType)
        {
            return (BillPrintType)
                Enum.Parse(typeof (BillPrintType), printType, true);
        }

        static string StripTemplateExtension(string template)
        {
            return string.IsNullOrWhiteSpace(template) 
                ? template
                : template.Replace(Rdl, string.Empty).Replace(Qrp, string.Empty);
        }
    }
}
