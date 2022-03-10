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
using InprotechKaizen.Model.Persistence;
using EntityModel = InprotechKaizen.Model.StandingInstructions;

namespace Inprotech.Web.Picklists
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/picklists/instructions")]
    public class InstructionsPicklistController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly IInstructionsPicklistMaintenance _instructionsPicklistMaintenance;

        public InstructionsPicklistController(IDbContext dbContext, IPreferredCultureResolver preferredCultureResolver,
                                              IInstructionsPicklistMaintenance instructionsPicklistMaintenance)
        {
            _dbContext = dbContext;
            _preferredCultureResolver = preferredCultureResolver;
            _instructionsPicklistMaintenance = instructionsPicklistMaintenance;
        }

        [HttpGet]
        [Route("meta")]
        [PicklistPayload(typeof(Instruction), ApplicationTask.MaintainBaseInstructions)]
        public dynamic Metadata()
        {
            return null;
        }

        [HttpGet]
        [Route]
        [PicklistPayload(typeof(Instruction), ApplicationTask.MaintainBaseInstructions)]
        public PagedResults Instructions(int typeId, [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")] CommonQueryParameters queryParameters = null, string search = "")
        {
            return Helpers.GetPagedResults(MatchingItems(typeId, search),
                                           queryParameters,
                                           null, x => x.Description, search);
        }

        [HttpGet]
        [Route]
        public PagedResults AllInstructions([ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")] CommonQueryParameters queryParameters = null, string search = "")
        {
            return Helpers.GetPagedResults(AllInstructions(search),
                                           queryParameters,
                                           null, x => x.Description, search);
        }

        [HttpGet]
        [Route("{id}")]
        [PicklistPayload(typeof(Instruction), ApplicationTask.MaintainBaseInstructions)]
        public Instruction Instruction(short id)
        {
            return MatchingItems(null, string.Empty, id).Single();
        }

        [HttpPut]
        [Route("{id}")]
        [RequiresAccessTo(ApplicationTask.MaintainBaseInstructions)]
        public dynamic Update(short id, Instruction instruction)
        {
            if (instruction == null) throw new ArgumentNullException(nameof(instruction));

            return _instructionsPicklistMaintenance.Save(instruction, Operation.Update);
        }

        [HttpPost]
        [Route]
        [RequiresAccessTo(ApplicationTask.MaintainBaseInstructions)]
        public dynamic AddOrDuplicate(Instruction instruction)
        {
            if (instruction == null) throw new ArgumentNullException(nameof(instruction));

            return _instructionsPicklistMaintenance.Save(instruction, Operation.Add);
        }

        [HttpDelete]
        [Route("{id}")]
        public dynamic Delete(short id)
        {
            return _instructionsPicklistMaintenance.Delete(id);
        }

        [HttpGet]
        [Route("instructionTypes")]
        public IEnumerable<dynamic> InstructionTypes()
        {
            var culture = _preferredCultureResolver.Resolve();
            return (from i in _dbContext.Set<EntityModel.InstructionType>()
                    select new
                           {
                               i.Id,
                               Description = DbFuncs.GetTranslation(i.Description, null, i.DescriptionTId, culture)
                           }).ToArray();
        }

        IEnumerable<Instruction> MatchingItems(int? typeId, string search = "", short? instructionId = null)
        {
            var culture = _preferredCultureResolver.Resolve();
            var interim = from i in _dbContext.Set<EntityModel.Instruction>()
                          join it in _dbContext.Set<EntityModel.InstructionType>() on i.InstructionTypeCode equals it.Code into it1
                          from it in it1
                          select new Instruction
                                 {
                                     Id = i.Id,
                                     TypeId = it.Id,
                                     Description = DbFuncs.GetTranslation(i.Description, null, i.DescriptionTId, culture),
                                     TypeDescription = DbFuncs.GetTranslation(it.Description, null, it.DescriptionTId, culture)
                                 };

            var r = instructionId.HasValue
                ? interim.Where(_ => _.Id == instructionId).ToArray()
                : interim.Where(_ => _.TypeId == typeId).ToArray();

            return !string.IsNullOrWhiteSpace(search)
                ? r.Where(_ => _.Description.IndexOf(search, StringComparison.InvariantCultureIgnoreCase) > -1)
                : r;
        }

        IEnumerable<Instruction> AllInstructions(string search = "")
        {
            var culture = _preferredCultureResolver.Resolve();
            var interim = _dbContext.Set<EntityModel.Instruction>()
                                    .Select(_ => new Instruction
                                    {
                                        Id = _.Id,
                                        Description = DbFuncs.GetTranslation(_.Description, null, _.DescriptionTId, culture)
                                    }).OrderBy(_ => _.Description);

            var r = interim.ToArray();

            return !string.IsNullOrWhiteSpace(search)
                ? r.Where(_ => _.Description.IndexOf(search, StringComparison.InvariantCultureIgnoreCase) > -1)
                : r;

        }
    }

    public class Instruction
    {

        [PicklistKey]
        public short? Id { get; set; }

        [Required]
        [MaxLength(50)]
        [PicklistDescription]
        public string Description { get; set; }

        [DisplayName("TypeDescription")]
        public string TypeDescription { get; set; }

        [Required]
        public int? TypeId { get; set; }
    }
}