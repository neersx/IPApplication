using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using Inprotech.Web.ProvideInstructions;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.ProvideInstructions
{
    public class ProvideInstructionsControllerFacts : FactBase
    {
        [Fact]
        public async Task VerifyGetProvideInstructions()
        {
            var fixture = new ProvideInstructionsControllerFixture();
            var taskPlannerRowKey = Fixture.String();
            var result = new
            {
                EventText = Fixture.String(),
                EventDueDate = Fixture.Date(),
                Instructions = new List<CaseInstruction>()
            };
            fixture.ProvideInstructionManager.GetInstructions(Arg.Any<string>())
                   .Returns(result);
            var r = await fixture.Subject.GetProvideInstructions(taskPlannerRowKey);
            Assert.Equal(result, r);
        }

        [Fact]
        public async Task GetProvideInstructionsShouldThrowArgumentNullException()
        {
            var fixture = new ProvideInstructionsControllerFixture();
            await Assert.ThrowsAsync<ArgumentNullException>(async () => { await fixture.Subject.GetProvideInstructions(null); });
        }

        [Fact]
        public async Task VerifyInstruct()
        {
            var fixture = new ProvideInstructionsControllerFixture();
            var request = new InstructionsRequest
            {
                TaskPlannerRowKey = Fixture.String(),
                ProvideInstruction = new ProvideInstructionList
                {
                    Instructions = new List<Instruction>
                    {
                        new () { ResponseLabel = Fixture.String() }
                    }
                }
            };

            fixture.ProvideInstructionManager.Instruct(Arg.Any<InstructionsRequest>())
                   .Returns(true);
            var r = await fixture.Subject.Instruct(request);
            Assert.True(r);
        }
        
        [Fact]
        public async Task InstructShouldThrowArgumentNullException()
        {
            var fixture = new ProvideInstructionsControllerFixture();
            await Assert.ThrowsAsync<ArgumentNullException>(async () => { await fixture.Subject.Instruct(new InstructionsRequest()); });
        }

    }

    public class ProvideInstructionsControllerFixture : IFixture<ProvideInstructionsController>
    {
        public ProvideInstructionsControllerFixture()
        {
            ProvideInstructionManager = Substitute.For<IProvideInstructionManager>();
            Subject = new ProvideInstructionsController(ProvideInstructionManager);
        }

        public IProvideInstructionManager ProvideInstructionManager { get; }

        public ProvideInstructionsController Subject { get; }
    }
}