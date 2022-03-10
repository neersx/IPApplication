using System.Text;
using System.Threading.Tasks;
using Inprotech.Contracts;
using InprotechKaizen.Model.Components.Accounting.Billing.Generation;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Accounting.Billing.Delivery
{

    public interface IBillXmlProfileResolver
    {
        Task<string> Resolve(string procedureName, BillGenerationRequest request);
    }

    public class BillXmlProfileResolver : IBillXmlProfileResolver
    {
        readonly IDbContext _dbContext;
        readonly ILogger<BillXmlProfileResolver> _logger;

        public BillXmlProfileResolver(IDbContext dbContext, ILogger<BillXmlProfileResolver> logger)
        {
            _dbContext = dbContext;
            _logger = logger;
        }

        public async Task<string> Resolve(string procedureName, BillGenerationRequest request)
        {
            // RFC9599, SQA7743 
            using var command = _dbContext.CreateStoredProcedureCommand(procedureName,
                                                                        new Parameters
                                                                        {
                                                                            { "@pnItemEntityNo", request.ItemEntityId },
                                                                            { "@pnItemTransNo", request.ItemTransactionId },
                                                                            { "@psOpenItemNo", request.OpenItemNo },
                                                                            { "@psLoginId", request.LoginId }
                                                                        });

            using var dr = await command.ExecuteReaderAsync();
            var billXmlProfileBuilder = new StringBuilder("<BillingProfile>");

            while (true)
            {
                while (await dr.ReadAsync()) billXmlProfileBuilder.Append(dr.GetString(0));

                if (!await dr.NextResultAsync())
                {
                    break;
                }
            }

            billXmlProfileBuilder.Append("</BillingProfile>");

            var r = billXmlProfileBuilder.ToString();

            _logger.Trace($"Executed {procedureName} to resolve Bill Xml Profile [{request.ItemEntityId}/{request.ItemTransactionId}/{request.OpenItemNo}/{request.LoginId}]", r);

            return r;
        }
    }
}