using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Web.Http;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using InprotechKaizen.Model.Components.Configuration.Rules.StandingInstructions;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.StandingInstructions;
using Newtonsoft.Json.Linq;

namespace Inprotech.Web.Configuration.Core
{
    [Authorize]
    [RequiresAccessTo(ApplicationTask.MaintainBaseInstructions)]
    public class InstructionTypesController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly IInstructionTypeSaveModel _instructionTypeSaveModel;

        public InstructionTypesController(IDbContext dbContext, IInstructionTypeSaveModel instructionTypeSaveModel)
        {
            _dbContext = dbContext;
            _instructionTypeSaveModel = instructionTypeSaveModel;
        }

        [HttpGet]
        [Route("api/instructiontypes")]
        [NoEnrichment]
        public dynamic InstructionTypes()
        {
            return _dbContext.Set<InstructionType>()
                             .Select(_ =>
                                         new
                                         {
                                             _.Id,
                                             _.Code,
                                             _.Description
                                         })
                             .ToArray();
        }

        [HttpGet]
        [Route("api/configuration/instructiontypedetails/{typeId}")]
        [NoEnrichment]
        public dynamic InstructionTypesDetails(int typeId)
        {
            var details = _dbContext.Set<InstructionType>()
                                    .Include(_ => _.Instructions.Select(i => i.Characteristics))
                                    .Include(_ => _.Characteristics)
                                    .Single(_ => _.Id == typeId);

            var ids = details.Characteristics.Select(c => c.Id).ToArray();

            return new
                   {
                       Characteristics = from c in details.Characteristics
                                         orderby c.Description
                                         select new
                                                {
                                                    c.Id,
                                                    c.Description
                                                },
                       Instructions = from i in details.Instructions
                                      orderby i.Description
                                      select new
                                             {
                                                 i.Id,
                                                 i.Description,
                                                 Characteristics = ids.Select(c => new
                                                                                   {
                                                                                       Id = c,
                                                                                       Selected = i.Characteristics.Select(_ => _.CharacteristicId).Contains(c)
                                                                                   })
                                             }
                   };
        }

        [HttpPost]
        [Route("api/configuration/instructiontypedetails/save")]
        [NoEnrichment]
        public dynamic Save(JObject modifiedModel)
        {
            if (modifiedModel == null) throw new ArgumentNullException(nameof(modifiedModel));
            var modifiedData = modifiedModel["instrType"].ToObject<DeltaInstructionTypeDetails>();

            if (_instructionTypeSaveModel.Save(modifiedData, out ValidationResult result))
            {
                return new
                       {
                           Result = "success",
                           Data = GetSavedDataWithCorrelationId(modifiedData)
                       };
            }

            return result;
        }

        dynamic GetSavedDataWithCorrelationId(DeltaInstructionTypeDetails data)
        {
            var savedData = InstructionTypesDetails(data.Id);
            var correlatedCharacteristics = new List<dynamic>();
            var savedCharacteristics = savedData.Characteristics;

            foreach (var c in savedCharacteristics)
            {
                var o = data.Characteristics.Added.SingleOrDefault(_ => c.Id == short.Parse(_.CorrelationId));
                correlatedCharacteristics.Add(
                                              new
                                              {
                                                  c.Id,
                                                  c.Description,
                                                  CorrelationId = o != null ? o.Id : string.Empty
                                              });
            }

            var correlatedInstructions = new List<dynamic>();
            var savedinstructions = savedData.Instructions;
            foreach (var i in savedinstructions)
            {
                var o = data.Instructions.Added.SingleOrDefault(_ => i.Id == short.Parse(_.CorrelationId));
                correlatedInstructions.Add(
                                           new
                                           {
                                               i.Id,
                                               i.Description,
                                               i.Characteristics,
                                               CorrelationId = o != null ? o.Id : string.Empty
                                           });
            }

            return new
                   {
                       characteristics = correlatedCharacteristics,
                       instructions = correlatedInstructions
                   };
        }
    }
}