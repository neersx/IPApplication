using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Localisation;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Configuration.Items;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Security;

namespace Inprotech.Web.Configuration.Search
{
    public interface IConfigurableItems
    {
        bool Any();

        Task<IEnumerable<AuthorisedConfigItems>> Retrieve();

        Task<int[]> Save(ConfigItem configItem);
    }

    public class ConfigurableItems : IConfigurableItems
    {
        readonly Func<DateTime> _clock;
        readonly IDbContext _dbContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly ISecurityContext _securityContext;

        public ConfigurableItems(IDbContext dbContext, ISecurityContext securityContext, IPreferredCultureResolver preferredCultureResolver, Func<DateTime> clock)
        {
            _dbContext = dbContext;
            _securityContext = securityContext;
            _preferredCultureResolver = preferredCultureResolver;
            _clock = clock;
        }

        public async Task<IEnumerable<AuthorisedConfigItems>> Retrieve()
        {
            var culture = _preferredCultureResolver.Resolve();
            var authorisedTasks = AuthorizedTasks().ToArray();

            var item = await IndividualConfigItems(culture, authorisedTasks);

            var grouped = await GroupedConfigItems(culture);

            var moreThanOne = (from i in item
                               where i.GroupId.HasValue
                               group i by i.GroupId
                               into groupedItems
                               select new
                               {
                                   GroupId = groupedItems.Key.Value,
                                   Count = groupedItems.Count()
                               })
                .Where(_ => _.Count > 1)
                .Select(_ => _.GroupId)
                .ToArray();

            var result = new List<AuthorisedConfigItems>();

            foreach (var e in item)
            {
                if (e.GroupId.HasValue && moreThanOne.Contains(e.GroupId.Value))
                {
                    continue;
                }

                result.Add(e);
            }

            foreach (var e in grouped)
            {
                if (moreThanOne.Contains(e.GroupId.Value))
                {
                    result.Add(e);
                }
            }

            return result;
        }

        public bool Any()
        {
            return AuthorizedTasks().Any();
        }

        public async Task<int[]> Save(ConfigItem configItem)
        {
            var updateValues = (configItem.Id.HasValue ? new[] {configItem.Id.Value} : new int[0])
                .Concat(configItem.Ids ?? new int[0])
                .Select(_ => new ConfigurationItemUpdateDetails
                {
                    Id = _,
                    Tags = configItem.Tags.ToArray()
                })
                .ToArray();

            return await SaveTags(updateValues);
        }

        async Task<int[]> SaveTags(ConfigurationItemUpdateDetails[] newValues)
        {
            var userId = _securityContext.User.Id;
            var today = _clock().Date;
            var idsToUpdate = newValues.Select(_ => _.Id);
            var authorisedTasks = (from p in _dbContext.PermissionsGranted(userId, "TASK", null, null, today)
                                   where p.CanDelete || p.CanExecute || p.CanInsert || p.CanUpdate
                                   join c in _dbContext.Set<ConfigurationItem>() on new {taskId = p.ObjectIntegerKey} equals new {taskId = (int) c.TaskId} into c1
                                   from c in c1
                                   where idsToUpdate.Contains(c.Id)
                                   select c).ToArray();

            var updated = new List<int>();

            foreach (var configurationItem in authorisedTasks)
            {
                var tagIdsToAdd = newValues.Single(_ => _.Id == configurationItem.Id).Tags.Select(_ => _.Id).ToList();
                var tagsToAdd = _dbContext.Set<Tag>().Where(_ => tagIdsToAdd.Contains(_.Id));

                configurationItem.Tags.Clear();
                configurationItem.Tags.AddRange(tagsToAdd);

                updated.Add(configurationItem.Id);
            }

            await _dbContext.SaveChangesAsync();

            return updated.ToArray();
        }

        IQueryable<int> AuthorizedTasks()
        {
            var userId = _securityContext.User.Id;
            var today = _clock().Date;
            return from p in _dbContext.PermissionsGranted(userId, "TASK", null, null, today)
                   where p.CanDelete || p.CanExecute || p.CanInsert || p.CanUpdate
                   join c in _dbContext.Set<ConfigurationItem>() on new {taskId = p.ObjectIntegerKey} equals new {taskId = (int) c.TaskId} into c1
                   from c in c1
                   select c.Id;
        }

        async Task<AuthorisedConfigItems[]> IndividualConfigItems(string culture, int[] authorisedIds)
        {
            var configItems = _dbContext.Set<ConfigurationItem>();

            var tasks = _dbContext.Set<SecurityTask>();

            return await (from c in configItems
                          join t in tasks on new {taskId = (int?) c.TaskId} equals new {taskId = (int?) t.Id} into t1
                          from t in t1.DefaultIfEmpty()
                          where authorisedIds.Contains(c.Id)
                          select new AuthorisedConfigItems
                          {
                              Id = c.Id,
                              GroupId = c.GroupId,
                              Components = c.Components.Select(_ => new
                              {
                                  _.Id,
                                  ComponentName = DbFuncs.GetTranslation(_.ComponentName, null, _.ComponentNameTId, culture)
                              }),
                              Tags = c.Tags,
                              Name = c.Title == null
                                  ? DbFuncs.GetTranslation(t.Name, null, t.TaskNameTId, culture)
                                  : DbFuncs.GetTranslation(c.Title, null, c.TitleTId, culture),
                              Description = c.Description == null
                                  ? DbFuncs.GetTranslation(t.Description, null, t.DescriptionTId, culture)
                                  : DbFuncs.GetTranslation(c.Description, null, c.DescriptionTId, culture),
                              Url = c.Url,
                              IeOnly = c.IeOnly
                          }).ToArrayAsync();
        }

        async Task<AuthorisedConfigItems[]> GroupedConfigItems(string culture)
        {
            var configItems = _dbContext.Set<ConfigurationItem>().Where(_ => _.GroupId != null);

            var configItemGroups = _dbContext.Set<ConfigurationItemGroup>();

            var groupedDetails = (from c in configItems
                                  group c by c.GroupId
                                  into g1
                                  select new
                                  {
                                      g1.Key,
                                      Ids = g1.Select(_ => _.Id),
                                      Components = g1
                                          .SelectMany(_ => _.Components
                                                            .Select(a =>
                                                                        new
                                                                        {
                                                                            ComponentName = DbFuncs.GetTranslation(a.ComponentName, null, a.ComponentNameTId, culture),
                                                                            a.Id
                                                                        })).Distinct(),
                                      Tags = g1.SelectMany(_ => _.Tags).Distinct(),
                                  }).ToDictionary(k => k.Key, v => new {v.Ids, v.Components, v.Tags});

            return (await (from cg in configItemGroups
                           join c in configItems on cg.Id equals c.GroupId into c1
                           from c in c1
                           select new AuthorisedConfigItems
                           {
                               GroupId = cg.Id,
                               Name = DbFuncs.GetTranslation(cg.Title, null, cg.TitleTId, culture),
                               Description = DbFuncs.GetTranslation(cg.Description, null, cg.DescriptionTId, culture),
                               Url = cg.Url,
                               IeOnly = c.IeOnly
                           })
                    .ToArrayAsync())
                .DistinctBy(_ => _.GroupId)
                .Select(_ => new AuthorisedConfigItems
                {
                    Ids = groupedDetails[_.GroupId.GetValueOrDefault()].Ids.ToArray(),
                    Tags = groupedDetails[_.GroupId.GetValueOrDefault()].Tags.ToArray(),
                    Components = groupedDetails[_.GroupId.GetValueOrDefault()].Components.ToArray(),
                    GroupId = _.GroupId,
                    Name = _.Name,
                    Description = _.Description,
                    Url = _.Url,
                    IeOnly = _.IeOnly
                })
                .ToArray();
        }
    }

    public class AuthorisedConfigItems
    {
        public AuthorisedConfigItems()
        {
            Components = new Component[0];

            Tags = new Tag[0];

            Ids = new int[0];
        }

        public int? Id { get; set; }

        public IEnumerable<int> Ids { get; set; }

        public int? GroupId { get; set; }

        public string Name { get; set; }

        public string Description { get; set; }

        public string Url { get; set; }

        public bool IeOnly { get; set; }

        public IEnumerable<dynamic> Components { get; set; }

        public IEnumerable<Tag> Tags { get; set; }
    }
}