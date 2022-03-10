using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure;
using Inprotech.Integration.IPPlatform.FileApp.Models;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Ede;
using InprotechKaizen.Model.Ede.DataMapping;
using InprotechKaizen.Model.Integration;
using InprotechKaizen.Model.Integration.PtoAccess;
using InprotechKaizen.Model.Persistence;
using FileCase = Inprotech.Integration.IPPlatform.FileApp.Models.FileCase;
using InprotechCase = InprotechKaizen.Model.Cases.Case;

namespace Inprotech.Integration.IPPlatform.FileApp.Builders
{
    public class FileTrademarkCaseBuilder : IFileCaseBuilder
    {
        readonly IDbContext _dbContext;
        readonly ISiteControlReader _siteControlReader;
        readonly IEventMappingsResolver _eventMappingsResolver;

        public FileTrademarkCaseBuilder(IDbContext dbContext, ISiteControlReader siteControlReader, IEventMappingsResolver eventMappingsResolver)
        {
            _dbContext = dbContext;
            _siteControlReader = siteControlReader;
            _eventMappingsResolver = eventMappingsResolver;
        }

        public async Task<FileCase> Build(string parentCaseId)
        {
            if (parentCaseId == null) throw new ArgumentNullException(nameof(parentCaseId));

            var caseId = int.Parse(parentCaseId);

            var firstOwner = (from c in _dbContext.Set<CaseName>()
                              where c.NameTypeId == KnownNameTypes.Owner && c.CaseId == caseId
                              orderby c.Sequence
                              select c.Name)
                .First()
                .Formatted();

            var eventsMap = _eventMappingsResolver.Resolve(new[]
            {
                Events.Application
            }, "FILE");

            eventsMap.TryGetValue(Events.Application, out var caseAppEvents);

            var caseAppNumber = _dbContext.Set<OfficialNumber>().Where(_ => _.IsCurrent == 1 && _.NumberTypeId == DbFuncs.ResolveMapping(KnownMapStructures.NumberType, KnownEncodingSchemes.CpaXml, "Application", "FILE"));
            var innographyId = _dbContext.Set<CpaGlobalIdentifier>().Where(_ => _.IsActive);

            var fileCase = await (from c in _dbContext.Set<InprotechCase>()
                                  join guid in innographyId on c.Id equals guid.CaseId into guid1
                                  from guid in guid1.DefaultIfEmpty()
                                  join ceApp in caseAppEvents on c.Id equals ceApp.CaseId into ceApp1
                                  from ceApp in ceApp1.DefaultIfEmpty()
                                  join nApp in caseAppNumber on c.Id equals nApp.CaseId into nApp1
                                  from nApp in nApp1.DefaultIfEmpty()
                                  where c.Id == caseId
                                  select new
                                  {
                                      CountryCode = c.Country.Id,
                                      CaseId = c.Id,
                                      CaseReference = c.Irn,
                                      CaseGuid = guid != null ? guid.InnographyId : null,
                                      c.Title,
                                      ApplicationNumber = nApp != null ? nApp.Number : null,
                                      ApplicationDate = ceApp != null ? ceApp.EventDate : null,
                                      PropertyId = c.PropertyType.Code,
                                      Case = c
                                  }).SingleAsync();

            var classTexts = GoodsAndServicesInPreferredLanguage(fileCase.Case);

            var i = 1;
            return new FileCase
            {
                Id = fileCase.CaseId.ToString(),
                CaseReference = fileCase.CaseReference,
                CaseGuid = fileCase.CaseGuid,
                ApplicantName = firstOwner,
                IpType = IpTypes.TrademarkDirect,
                BibliographicalInformation = new Biblio
                {
                    Title = fileCase.Title,
                    Mark = fileCase.Title,
                    PriorityCountry = fileCase.CountryCode,
                    PriorityNumber = PriorityNumber(fileCase.ApplicationNumber),
                    PriorityDate = DateOrNull(fileCase.ApplicationDate),
                    ClaimsPriority = true,
                    Classes = (from gs in classTexts
                               select new BibloClasses
                               {
                                   Id = i++,
                                   Name = gs.Class,
                                   Description = gs.LongText ?? gs.ShortText
                               }).ToList()
                }
            };
        }

        IEnumerable<CaseText> GoodsAndServicesInPreferredLanguage(InprotechCase @case)
        {
            var goodsServicesLanguage = _siteControlReader.Read<int?>(SiteControls.FILEDefaultLanguageforGoodsandServices);

            return @case.GoodsAndServices()
                        .Where(_ => _.Language == null || _.Language == goodsServicesLanguage)
                        .GroupBy(t => t.Class)
                        .Select(g => g.OrderByDescending(_ => _.Language).ThenByDescending(t => t.Number).First())
                        .ToArray();
        }

        static string DateOrNull(DateTime? date)
        {
            return date?.ToString("yyyy-MM-dd");
        }

        static string PriorityNumber(string number)
        {
            return string.IsNullOrWhiteSpace(number) ? null : number;
        }
    }
}