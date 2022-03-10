using System.Collections.Generic;
using Inprotech.Infrastructure.Web;

namespace Inprotech.Web.Search.Columns
{
    public interface IQueryContextTypeResolver
    {
        QueryContextType Resolve(QueryContext queryContext);
    }

    public class QueryContextTypeResolver : IQueryContextTypeResolver
    {
        static readonly Dictionary<QueryContext, QueryContextType> QueryContextTypeMap =
            new Dictionary<QueryContext, QueryContextType>
            {
                {QueryContext.CaseSearch, QueryContextType.Internal},
                {QueryContext.CaseSearchExternal, QueryContextType.External},
                {QueryContext.NameSearch, QueryContextType.Internal},
                {QueryContext.NameSearchExternal, QueryContextType.External},
                {QueryContext.WipOverviewSearch, QueryContextType.Internal},
                {QueryContext.MarketingEventSearch, QueryContextType.Internal},
                {QueryContext.PriorArtSearch, QueryContextType.Internal},
                {QueryContext.LeadSearch, QueryContextType.Internal},
                {QueryContext.OpportunitySearch, QueryContextType.Internal},
                {QueryContext.CampaignSearch, QueryContextType.Internal},
                {QueryContext.WorkHistorySearch, QueryContextType.Internal},
                {QueryContext.CaseFeeSearchInternal, QueryContextType.Internal},
                {QueryContext.CaseFeeSearchExternal, QueryContextType.External},
                {QueryContext.ReciprocitySearch, QueryContextType.Internal},
                {QueryContext.CaseInstructionSearchInternal, QueryContextType.Internal},
                {QueryContext.CaseInstructionSearchExternal, QueryContextType.External},
                {QueryContext.AdHocDateSearch, QueryContextType.Internal},
                {QueryContext.ClientRequestSearchInternal, QueryContextType.Internal},
                {QueryContext.ClientRequestSearchExternal, QueryContextType.External},
                {QueryContext.RemindersSearch, QueryContextType.Internal},
                {QueryContext.ToDo, QueryContextType.Internal},
                {QueryContext.WhatsDueCalendar, QueryContextType.Internal},
                {QueryContext.TaskPlanner, QueryContextType.Internal}
            };

        public QueryContextType Resolve(QueryContext queryContext)
        {
            if (!QueryContextTypeMap.TryGetValue(queryContext, out var queryContextType))
            {
                queryContextType = QueryContextType.NotDefined;
            }

            return queryContextType;
        }
    }

    public enum QueryContextType
    {
        NotDefined = -1,
        Internal = 1,
        External = 2
    }
    
    public class QueryContextGroup
    {
        public static readonly Dictionary<QueryContext, QueryContext[]> QueryContextDictionary = new Dictionary<QueryContext, QueryContext[]>
        {
            {QueryContext.CaseSearch, new[] {QueryContext.CaseSearch, QueryContext.CaseSearchExternal}},
            {QueryContext.CaseSearchExternal, new[] {QueryContext.CaseSearch,QueryContext.CaseSearchExternal}},
            {QueryContext.NameSearch, new[] {QueryContext.NameSearch, QueryContext.NameSearchExternal}},
            {QueryContext.NameSearchExternal, new[] {QueryContext.NameSearch,QueryContext.NameSearchExternal}},
            {QueryContext.CaseFeeSearchInternal, new[] {QueryContext.CaseFeeSearchInternal,QueryContext.CaseFeeSearchExternal}},
            {QueryContext.CaseFeeSearchExternal, new[] {QueryContext.CaseFeeSearchInternal,QueryContext.CaseFeeSearchExternal}},
            {QueryContext.ClientRequestSearchInternal, new[] {QueryContext.ClientRequestSearchInternal,QueryContext.ClientRequestSearchExternal}},
            {QueryContext.ClientRequestSearchExternal, new[] {QueryContext.ClientRequestSearchInternal,QueryContext.ClientRequestSearchExternal}},
            {QueryContext.CaseInstructionSearchInternal, new[] {QueryContext.CaseInstructionSearchInternal,QueryContext.CaseInstructionSearchExternal}},
            {QueryContext.CaseInstructionSearchExternal, new[] {QueryContext.CaseInstructionSearchInternal,QueryContext.CaseInstructionSearchExternal}}
        };
    }
}