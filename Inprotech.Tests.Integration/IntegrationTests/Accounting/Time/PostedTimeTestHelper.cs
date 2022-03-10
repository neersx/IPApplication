using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Utils;
using Inprotech.Web.Accounting.Time;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Accounting.Work;
using InprotechKaizen.Model.Components.Accounting;
using InprotechKaizen.Model.Components.Accounting.Time;
using InprotechKaizen.Model.Names;
using Newtonsoft.Json;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.IntegrationTests.Accounting.Time
{
    public static class PostedTimeTestHelper
    {
        internal static PostedTime GetRecordableTime(Diary diary, Name entity)
        {
            return new PostedTime
            {
                ActivityKey = diary.Activity,
                Activity = diary.ActivityDetail.WipCode,
                CaseKey = diary.CaseId,
                EntityNo = entity.Id,
                EntryNo = diary.EntryNo,
                Start = diary.StartTime,
                EntryDate = diary.StartTime?.Date ?? DateTime.Today,
                Finish = diary.FinishTime,
                TotalTime = diary.TotalTime,
                TotalUnits = diary.TotalUnits,
                NameKey = diary.NameNo,
                NarrativeNo = diary.NarrativeNo,
                StaffId = diary.EmployeeNo,
                NarrativeText = diary.ShortNarrative,
                TimeCarriedForward = diary.TimeCarriedForward
            };
        }

        internal static PostedTime ChangeDurationBy(PostedTime input, double hours)
        {
            input.Finish = input.Finish?.AddHours(hours);
            input.TotalTime = input.TotalTime?.AddHours(hours);

            return input;
        }

        internal static int PostEntry(Name entityName, Diary diary, TestUser user)
        {
            var request = new PostEntry {EntityKey = entityName.Id, EntryNo = diary.EntryNo, StaffNameId = user.NameId, PostingParams = null};
            ApiClient.Post<PostTimeResult>("accounting/time-posting/postEntry", JsonConvert.SerializeObject(request), user.Username);

            var transNo = 0;

            DbSetup.Do(x =>
            {
                var updatedDiary = x.DbContext.Set<Diary>().SingleOrDefault(_ => _.EntryNo == diary.EntryNo && _.EmployeeNo == user.NameId);
                Assert.NotNull(updatedDiary);

                Assert.True(updatedDiary.TransactionId.HasValue);
                Assert.True(updatedDiary.WipEntityId.HasValue);
                Assert.AreEqual(entityName.Id, updatedDiary.WipEntityId.Value);

                transNo = updatedDiary.TransactionId.Value;

                var wips = x.DbContext.Set<WorkInProgress>().Where(_ => _.TransactionId == updatedDiary.TransactionId && _.EntityId == updatedDiary.WipEntityId).ToList();
                AssertWipDetails(wips, new DateTime(1899, 1, 1, 2, 0, 0), 20, 10, 150, 300, 300, -30, -30, "Posted entry");

                var history = x.DbContext.Set<WorkHistory>().Where(_ => _.TransactionId == updatedDiary.TransactionId && _.EntityId == updatedDiary.WipEntityId && _.HistoryLineNo == 1).ToList();
                AssertWorkflowHistory(history, 20, 300, -30, MovementClass.Entered, MovementClass.Entered, "Posted entry");
            });

            return transNo;
        }

        internal static void AssertWipDetails(IList<WorkInProgress> wips, DateTime totalTime, int totalUnits, int unitsPerHour, decimal chargeOutRate, int localValue, int balance, int discount, double discountBalance, string assertionText)
        {
            var mainWip = wips.Single(_ => !_.WipIsDiscount());
            Assert.AreEqual(totalTime, mainWip.TotalTime, $"Total time of main wip is checked for: {assertionText}");
            Assert.AreEqual(totalUnits, mainWip.TotalUnits, $"Total units of main wip is checked for: {assertionText}");
            Assert.AreEqual(unitsPerHour, mainWip.UnitsPerHour, $"UnitsPerHours of main wip is checked for: {assertionText}");
            Assert.AreEqual(chargeOutRate, mainWip.ChargeOutRate, $"ChargeOutRate of main wip is checked for: {assertionText}");
            Assert.AreEqual(localValue, mainWip.LocalValue, $"LocalValue of main wip is checked for: {assertionText}");
            Assert.AreEqual(balance, mainWip.Balance, $"Balance of main wip is checked for: {assertionText}");

            Assert.AreEqual(2, wips.Count);
            var discountWip = wips.Single(_ => _.WipIsDiscount());
            Assert.Null(discountWip.TotalTime, $"Total time of discount wip is null for: {assertionText}");
            Assert.Null(discountWip.TotalUnits, $"Total units of discount wip is null for: {assertionText}");
            Assert.Null(discountWip.UnitsPerHour, $"UnitsPerHours of discount wip is null for: {assertionText}");
            Assert.Null(discountWip.ChargeOutRate, $"ChargeOutRate for discount wip is null for: {assertionText}");
            Assert.AreEqual(discount, discountWip.LocalValue, $"LocalValue of discount wip is checked for: {assertionText}");
            Assert.AreEqual(discountBalance, discountWip.Balance, $"Balance of discount wip is checked for: {assertionText}");
        }

        internal static void AssertWorkflowHistory(IList<WorkHistory> history, int totalUnits, int localTransactionValue, double discountTransValue, MovementClass movementClass, MovementClass discountMovementClass, string assertionText)
        {
            Assert.AreEqual(2, history.Count);

            var mainHistory = history.Single(_ => !_.IsDiscount);
            var discountHistory = history.Single(_ => _.IsDiscount);

            Assert.AreEqual(totalUnits, mainHistory.TotalUnits, $"Total units of main history item is checked for: {assertionText}");
            Assert.AreEqual(localTransactionValue, mainHistory.LocalValue, $"Transaction value of main history is checked for: {assertionText}");
            Assert.AreEqual(movementClass, mainHistory.MovementClass, $"MovementClass value of main history is checked for: {assertionText}");

            Assert.Null(discountHistory.TotalUnits, $"Total units of discount history is null for: {assertionText}");
            Assert.AreEqual(discountTransValue, discountHistory.LocalValue, $"Transaction value of discount history is checked for: {assertionText}");
            Assert.AreEqual(discountMovementClass, discountHistory.MovementClass, $"MovementClass value of discount history is checked for: {assertionText}");
        }
    }
}