
using System;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure.ResponseEnrichment;
using InprotechKaizen.Model.Components.System.Utilities;

namespace Inprotech.Web.Search.TempStorage
{
    [Authorize]
    [RoutePrefix("api/storeresolveditems")]
    public class StoreResolvedItemsController : ApiController
    {
        readonly ITempStorageHandler _tempStorageHandler;

        public StoreResolvedItemsController(ITempStorageHandler tempStorageHandler)
        {
            _tempStorageHandler = tempStorageHandler ?? throw new ArgumentNullException(nameof(tempStorageHandler));
        }

        [HttpPost]
        [Route("add")]
        [NoEnrichment]
        public async Task<long> Add(StoreResolvedItemsRequest request)
        {
            return await _tempStorageHandler.Add(request.Items);
        }
    }

    public class StoreResolvedItemsRequest
    {
        public string Items { get; set; }
    }
}
