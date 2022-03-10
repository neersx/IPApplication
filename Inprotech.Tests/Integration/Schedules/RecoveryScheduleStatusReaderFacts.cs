using System;
using System.Collections.ObjectModel;
using Autofac.Features.Indexed;
using Inprotech.Integration;
using Inprotech.Integration.Schedules;
using Inprotech.Tests.Fakes;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.Schedules
{
    public class RecoveryScheduleStatusReaderFacts : FactBase
    {
        public RecoveryScheduleStatusReaderFacts()
        {
            UsptoRecoveryValidation = Substitute.For<IValidateRecoveryScheduleStatus>();
            ValidateRecoveryScheduleList = Substitute.For<IIndex<DataSourceType, Func<IValidateRecoveryScheduleStatus>>>();
            reader = new RecoveryScheduleStatusReader(Db, ValidateRecoveryScheduleList);

            UsptoRecoveryValidation.Status(Arg.Any<Schedule>(), Arg.Any<ScheduleExecution>())
                                   .Returns(RecoveryScheduleStatus.Idle);

            ValidateRecoveryScheduleList.TryGetValue(DataSourceType.UsptoPrivatePair, out _)
                                        .Returns(x =>
                                        {
                                            Func<IValidateRecoveryScheduleStatus> f = () => UsptoRecoveryValidation;
                                            x[1] = f;
                                            return true;
                                        });
        }

        readonly IRecoveryScheduleStatusReader reader;
        IIndex<DataSourceType, Func<IValidateRecoveryScheduleStatus>> ValidateRecoveryScheduleList { get; }
        IValidateRecoveryScheduleStatus UsptoRecoveryValidation { get; }

        [Fact]
        public void ReturnsIdleIfExecutionIsFinished()
        {
            new Schedule
            {
                ParentId = 1,
                Type = ScheduleType.Retry,
                Executions = new Collection<ScheduleExecution>
                {
                    new ScheduleExecution
                    {
                        Status = ScheduleExecutionStatus.Complete
                    }
                }
            }.In(Db);

            var s = reader.Read(1);
            Assert.Equal(RecoveryScheduleStatus.Idle, s);
        }

        [Fact]
        public void ReturnsIdleIfRecoveryScheduleDoesNotExist()
        {
            new Schedule
            {
                ParentId = 1,
                Type = ScheduleType.OnDemand
            }.In(Db);

            var s = reader.Read(1);
            Assert.Equal(RecoveryScheduleStatus.Idle, s);
        }

        [Fact]
        public void ReturnsPendingIfExecutionIsNotCreatedYet()
        {
            new Schedule
            {
                ParentId = 1,
                Type = ScheduleType.Retry
            }.In(Db);

            var s = reader.Read(1);
            Assert.Equal(RecoveryScheduleStatus.Pending, s);
        }

        [Fact]
        public void ReturnsRunningIfExecutionIsRunning()
        {
            new Schedule
            {
                ParentId = 1,
                Type = ScheduleType.Retry,
                Executions = new Collection<ScheduleExecution>
                {
                    new ScheduleExecution
                    {
                        Status = ScheduleExecutionStatus.Started
                    }
                }
            }.In(Db);

            var s = reader.Read(1);
            Assert.Equal(RecoveryScheduleStatus.Running, s);
        }

        [Theory]
        [InlineData(DataSourceType.Epo, false)]
        [InlineData(DataSourceType.UsptoPrivatePair, true)]
        public void DoesNotValidateIfPostValidationNotRegisteredForDataSource(DataSourceType type, bool shouldCallPostValidation)
        {
            new Schedule
            {
                ParentId = 1,
                Type = ScheduleType.Retry,
                DataSourceType = type,
                Executions = new Collection<ScheduleExecution>
                {
                    new ScheduleExecution
                    {
                        Status = ScheduleExecutionStatus.Complete
                    }
                }
            }.In(Db);

            var s = reader.Read(1);
            Assert.Equal(RecoveryScheduleStatus.Idle, s);

            ValidateRecoveryScheduleList.Received(1).TryGetValue(type, out _);

            if (shouldCallPostValidation)
            {
                UsptoRecoveryValidation.Received(1).Status(Arg.Any<Schedule>(), Arg.Any<ScheduleExecution>());
            }
            else
            {
                UsptoRecoveryValidation.DidNotReceiveWithAnyArgs().Status(Arg.Any<Schedule>(), Arg.Any<ScheduleExecution>());
            }

        }
    }
}