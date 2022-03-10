using System;
using System.Collections.Generic;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Configuration.SiteControl;
using InprotechKaizen.Model.Queries;

namespace Inprotech.Tests.Web.Builders.Model.Common
{
    public class QueryBuilder : IBuilder<Query>
    {
        public int ContextId { get; set; }
        public int? IdentityId { get; set; }
        public string SearchName { get; set; }
        public string Description { get; set; }

        public Query Build()
        {
            return new Query() { ContextId = ContextId, Name = SearchName, Description = Description, IdentityId = IdentityId };
        }
    }
}