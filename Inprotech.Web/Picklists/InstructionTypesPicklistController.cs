using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.ResponseShaping.Picklists;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Picklists.ResponseShaping;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases.Extensions;
using InprotechKaizen.Model.Persistence;
using EntityModel = InprotechKaizen.Model.StandingInstructions;

namespace Inprotech.Web.Picklists
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/picklists/instructionTypes")]
    public class InstructionTypesPicklistController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly IInstructionTypesPicklistMaintenance _instructionTypesPicklistMaintenance;
        readonly IPreferredCultureResolver _preferredCultureResolver;

        public InstructionTypesPicklistController(IDbContext dbContext,
                                                  IPreferredCultureResolver preferredCultureResolver,
                                                  IInstructionTypesPicklistMaintenance instructionTypesPicklistMaintenance)
        {
            _dbContext = dbContext;
            _preferredCultureResolver = preferredCultureResolver;
            _instructionTypesPicklistMaintenance = instructionTypesPicklistMaintenance;
        }

        [HttpGet]
        [Route("meta")]
        [PicklistPayload(typeof (InstructionType), ApplicationTask.MaintainBaseInstructions)]
        public dynamic Metadata()
        {
            return null;
        }

        [HttpGet]
        [Route]
        [PicklistPayload(typeof (InstructionType), ApplicationTask.MaintainBaseInstructions)]
        public PagedResults InstructionTypes([ModelBinder(BinderType = typeof (JsonQueryBinder), Name = "params")] CommonQueryParameters queryParameters = null, string search = "")
        {
            return Helpers.GetPagedResults(MatchingItems(null, search),
                                           queryParameters,
                                           x => x.Code, x => x.Value, search);
        }

        [HttpGet]
        [Route("{typeId}")]
        [PicklistPayload(typeof (InstructionType), ApplicationTask.MaintainBaseInstructions)]
        public InstructionType InstructionType(int typeId)
        {
            return MatchingItems(typeId, string.Empty)
                .SingleOrDefault();
        }

        [HttpPut]
        [Route("{typeId}")]
        [RequiresAccessTo(ApplicationTask.MaintainBaseInstructions)]
        public dynamic Update(int typeId, InstructionType instructionType)
        {
            if (instructionType == null) throw new ArgumentNullException(nameof(instructionType));

            return _instructionTypesPicklistMaintenance.Save(instructionType, Operation.Update);
        }

        [HttpPost]
        [Route]
        [RequiresAccessTo(ApplicationTask.MaintainBaseInstructions)]
        public dynamic AddOrDuplicate(InstructionType instructionType)
        {
            if (instructionType == null) throw new ArgumentNullException(nameof(instructionType));

            return _instructionTypesPicklistMaintenance.Save(instructionType, Operation.Add);
        }

        [HttpDelete]
        [Route("{typeId}")]
        public dynamic Delete(int typeId)
        {
            return _instructionTypesPicklistMaintenance.Delete(typeId);
        }

        [HttpGet]
        [Route("nameTypes")]
        public IEnumerable<dynamic> NameTypes()
        {
            var culture = _preferredCultureResolver.Resolve();

            var allNameTypes = _dbContext.Set<NameType>()
                                         .WithoutUnrestricted().OrderBy(_ => _.Name);

            return from nt in allNameTypes
                   select new
                          {
                              Key = nt.NameTypeCode,
                              Value = DbFuncs.GetTranslation(nt.Name, null, nt.NameTId, culture)
                          };
        }

        IEnumerable<InstructionType> MatchingItems(int? typeId, string search)
        {
            var culture = _preferredCultureResolver.Resolve();

            var q = _dbContext.Set<EntityModel.InstructionType>()
                              .Where(_ => typeId == null || _.Id == typeId);

            var interim =
                (from instructionType in q
                 select new InstructionType
                        {
                            Key = instructionType.Id,
                            Code = instructionType.Code,
                            Value = DbFuncs.GetTranslation(instructionType.Description, null, instructionType.DescriptionTId, culture) ?? string.Empty,
                            RecordedAgainst = DbFuncs.GetTranslation(instructionType.NameType.Name, null, instructionType.NameType.NameTId, culture),
                            RecordedAgainstId = instructionType.NameType.NameTypeCode,
                            RestrictedBy = instructionType.RestrictedByType != null ? DbFuncs.GetTranslation(instructionType.RestrictedByType.Name, null, instructionType.RestrictedByType.NameTId, culture) : null,
                            RestrictedById = instructionType.RestrictedByType == null ? null : instructionType.RestrictedByType.NameTypeCode
                        }).ToArray();

            return !string.IsNullOrWhiteSpace(search)
                ? interim.Where(_ => _.Code.IndexOf(search, StringComparison.InvariantCultureIgnoreCase) > -1 ||
                                     _.Value.IndexOf(search, StringComparison.InvariantCultureIgnoreCase) > -1)
                : interim;
        }
    }

    public class InstructionType
    {
        [PicklistKey]
        public int? Key { get; set; }

        [Required]
        [MaxLength(3)]
        [DisplayName("Code")]
        [PreventCopy]
        [PicklistCode]
        public string Code { get; set; }

        [Required]
        [MaxLength(50)]
        [PicklistDescription]
        public string Value { get; set; }

        [DisplayName("RecordedAgainst")]
        public string RecordedAgainst { get; set; }

        [DisplayName("RestrictedBy")]
        public string RestrictedBy { get; set; }

        [Required]
        public string RecordedAgainstId { get; set; }

        public string RestrictedById { get; set; }
    }
}