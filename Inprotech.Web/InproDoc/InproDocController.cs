using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Threading.Tasks;
using System.Web.Http;
using AutoMapper;
using Inprotech.Contracts.Messages.Analytics;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Messaging;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Integration.Analytics;
using Inprotech.Web.InproDoc.Config;
using Inprotech.Web.InproDoc.Converter;
using Inprotech.Web.InproDoc.Dto;
using InprotechKaizen.Model.Components.DocumentGeneration.Processor;

namespace Inprotech.Web.InproDoc
{
    [Authorize]
    [NoEnrichment]
    public class InproDocController : ApiController
    {
        static IMapper _mapper;
        readonly IBus _bus;
        readonly IDocItemCommand _docItemCommand;
        readonly IRunDocItemsManager _docItemsRunner;
        readonly IDocumentService _documentCommand;
        readonly IPassThruManager _passthru;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly ISiteControlReader _siteControls;

        public InproDocController(IPassThruManager passthru,
                                  IRunDocItemsManager docItemsRunner,
                                  ISiteControlReader siteControls,
                                  IPreferredCultureResolver preferredCultureResolver,
                                  IDocItemCommand docItemCommand,
                                  IDocumentService documentCommand,
                                  IBus bus)
        {
            _passthru = passthru;
            _docItemsRunner = docItemsRunner;
            _siteControls = siteControls;
            _preferredCultureResolver = preferredCultureResolver;
            _docItemCommand = docItemCommand;
            _documentCommand = documentCommand;
            _bus = bus;
        }

        IMapper Config => _mapper ?? (_mapper = ConfigureMappers());

        static IMapper ConfigureMappers()
        {
            // The Mappers are required because the consumer of this service is in
            // a separate repository.  Using DTO can manage versioning conflicts.

            var config = new MapperConfiguration(cfg =>
            {
                cfg.CreateMap<ReferencedDataItem, DocItem>();
                cfg.CreateMap<DocItem, ReferencedDataItem>();
                cfg.CreateMap<ItemProcessorRequest, ItemProcessor>()
                   .ForMember(_ => _.ReferencedDataItem,
                              opt => opt.MapFrom(m => m.DocItem));
                cfg.CreateMap<ItemProcessor, ItemProcessorResponse>();
                cfg.CreateMap<Exception, string>().ConvertUsing<ExceptionTypeConverter>();
                cfg.CreateMissingTypeMaps = true;
            });

            return config.CreateMapper();
        }

        [HttpPost]
        [ActionName("ping")]
        public string TryConnect()
        {
            return "pong";
        }

        [HttpPost]
        [ActionName("entry-points")]
        public IEnumerable<EntryPoint> LoadEntryPoints()
        {
            return _passthru.GetEntryPoints();
        }

        [HttpPost]
        [ActionName("doc-items")]
        public async Task<IEnumerable<DocItem>> ListDocItems()
        {
            await TrackTransaction(Request);

            var docItems = _docItemCommand.ListDocItems(_preferredCultureResolver.Resolve());

            return Config.Map<IEnumerable<ReferencedDataItem>, IEnumerable<DocItem>>(docItems);
        }

        [HttpPost]
        [ActionName("documents-by-type")]
        public DocumentList ListDocumentsByType(DocumentListRequest request)
        {
            if (request == null) throw new ArgumentNullException(nameof(request));

            return new DocumentList
            {
                LocalTemplatesPath = _siteControls.Read<string>(SiteControls.InproDocLocalTemplates),
                NetworkTemplatesPath = _siteControls.Read<string>(SiteControls.InproDocNetworkTemplates),
                Documents = _documentCommand.ListDocuments(_preferredCultureResolver.Resolve(),
                                                           (int)request.DocumentType,
                                                           (int)request.UsedBy,
                                                           (int)request.NotUsedBy)
            };
        }

        [HttpPost]
        [ActionName("run-doc-items")]
        public async Task<IEnumerable<ItemProcessorResponse>> ExecuteDocItems(ItemProcessorRequest[] itemProcessorsRequest)
        {
            await TrackTransaction(Request);

            var itemProcessors = Config.Map<IList<ItemProcessorRequest>, IList<ItemProcessor>>(itemProcessorsRequest);

            foreach (var itemProcessor in itemProcessors.Where(i => i.Fields != null && i.Fields.Count > 0))
            {
                itemProcessor.RowsReturnedMode = RowsReturnedMode.Single;
                if (itemProcessor.Fields.Exists(f => f.RowsReturnedMode == RowsReturnedMode.Multiple))
                {
                    itemProcessor.RowsReturnedMode = RowsReturnedMode.Multiple;
                }
            }

            var items = _docItemsRunner.Execute(itemProcessors);

            return Config.Map<IEnumerable<ItemProcessor>, IEnumerable<ItemProcessorResponse>>(items);
        }

        async Task TrackTransaction(HttpRequestMessage message)
        {
            if (!message.Headers.TryGetValues("x-inprodoc-version", out var version))
            {
                return;
            }

            if (!message.Headers.TryGetValues("x-inprodoc-sessionId", out var sessionId))
            {
                return;
            }

            await _bus.PublishAsync(new TransactionalAnalyticsMessage
            {
                EventType = TransactionalEventTypes.InprodocAdHocGeneration,
                Value = version.Single() + "^" + sessionId.Single()
            });
        }
    }
}