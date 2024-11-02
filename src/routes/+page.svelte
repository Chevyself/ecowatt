<script lang="ts">
	import { onMount } from 'svelte';
	import type { HomeDevice } from '$lib/types/HomeDevice';
	import { devices, getKwS } from '$lib/types/HomeDevice';
	import DeviceComponent from '../components/DeviceComponent.svelte';
	import Chart from 'chart.js/auto';
	let currentDevices: HomeDevice[] = [];
	let totalKwBeingConsumed: number = 0;
	let selectedTimeframe = 'Today';
  // Current time and set minute to 0
	let currentTime: number = new Date().setMinutes(0);
	let consumptionChart: Chart | null = null;
	let mounted = false;
	let socket: WebSocket | null;



	interface ConsumptionStat {
		timestamp: number;
		consumption: number;
	}

	// Stats
  // hourly has stats for every 10 minutes
  let thisHourConsumption: ConsumptionStat[] = [];
	// daily has stats for every hour
  let todayConsumption: ConsumptionStat[] = [];
	// monthly has stats for every day
  let thisMonthConsumption: ConsumptionStat[] = [];
	// yearly has stats for every month
  let thisYearConsumption: ConsumptionStat[] = [];

	function addDevice(device: HomeDevice) {
		currentDevices = [...currentDevices, { ...device }];
	}

	function updateChart() {
		if (!mounted) return;

		const ctx = document.getElementById('consumptionChart') as HTMLCanvasElement;
		const relevantStats = getRelevantStats(selectedTimeframe);

		if (consumptionChart) {
			consumptionChart.destroy();
		}

		const labels = relevantStats.map((stat) => {
			const date = new Date(stat.timestamp);
			switch (selectedTimeframe) {
				case 'This Hour':
					return date.getMinutes().toString().padStart(2, '0');
				case 'Today':
					return date.getHours().toString().padStart(2, '0') + ':00';
				case 'This Month':
					return date.getDate().toString();
				case 'This Year':
					return date.toLocaleString('default', { month: 'short' });
			}
		});

		const data = relevantStats.map((stat) => stat.consumption);

		consumptionChart = new Chart(ctx, {
			type: 'bar',
			data: {
				labels: labels,
				datasets: [
					{
						label: 'Power Consumption (kW)',
						data: data,
						backgroundColor: 'rgba(75, 192, 192, 0.6)',
						borderColor: 'rgba(75, 192, 192, 1)',
						borderWidth: 1
					}
				]
			},
			options: {
				responsive: true,
        animation: {
          duration: 0
        },
				scales: {
					y: {
						beginAtZero: true,
						title: {
							display: true,
							text: 'kW'
						}
					},
					x: {
						title: {
							display: true,
							text: getXAxisLabel(selectedTimeframe)
						}
					}
				}
			}
		});
	}

	function getXAxisLabel(timeframe: string): string {
		switch (timeframe) {
			case 'This Hour':
				return 'Minutes';
			case 'Today':
				return 'Hours';
			case 'This Month':
				return 'Days';
			case 'This Year':
				return 'Months';
			default:
				return '';
		}
	}

	function setTimeframe(timeframe: string) {
		selectedTimeframe = timeframe;
		updateChart();
	}

	function getRelevantStats(timeframe: string): ConsumptionStat[] {
		switch (timeframe) {
			case 'This Hour':
				return thisHourConsumption;
			case 'Today':
				return todayConsumption;
			case 'This Month':
				return thisMonthConsumption;
			case 'This Year':
				return thisYearConsumption;
			default:
				return [];
		}
	}

	function updateConsumptionData() {
		// Calculate total consumption
		totalKwBeingConsumed = currentDevices.reduce(
			(acc, device) => acc + (device.isOn ? getKwS(device) : 0),
			0
		);

		// Update time (1 second = 10 minutes in simulation)
		currentTime += 600000;

		// Update stats for different timeframes
		updateHourlyStats();
		updateDailyStats();
		updateMonthlyStats();
		updateYearlyStats();

		// Update the chart
		updateChart();
	}

	function updateHourlyStats() {
		const currentMinute = new Date(currentTime).getMinutes();
		if (currentMinute % 10 === 0) {
			thisHourConsumption.push({ timestamp: currentTime, consumption: totalKwBeingConsumed });
			if (thisHourConsumption.length > 6) {
				thisHourConsumption.shift();
			}
		}
	}

	function updateDailyStats() {
		const currentHour = new Date(currentTime).getHours();
		const currentMinute = new Date(currentTime).getMinutes();
		if (currentMinute === 0) {
			todayConsumption.push({ timestamp: currentTime, consumption: totalKwBeingConsumed });
			if (todayConsumption.length > 24) {
				todayConsumption.shift();
			}
		}
	}

	function updateMonthlyStats() {
		const currentDate = new Date(currentTime).getDate();
		const currentHour = new Date(currentTime).getHours();
		const currentMinute = new Date(currentTime).getMinutes();
		if (currentHour === 0 && currentMinute === 0) {
			const dailyAverage = calculateDailyAverage();
			thisMonthConsumption.push({ timestamp: currentTime, consumption: dailyAverage });
			if (thisMonthConsumption.length > 31) {
				thisMonthConsumption.shift();
			}
		}
	}

	function updateYearlyStats() {
		const currentMonth = new Date(currentTime).getMonth();
		const currentDate = new Date(currentTime).getDate();
		const currentHour = new Date(currentTime).getHours();
		const currentMinute = new Date(currentTime).getMinutes();
		if (currentDate === 1 && currentHour === 0 && currentMinute === 0) {
			const monthlyAverage = calculateMonthlyAverage();
			thisYearConsumption.push({ timestamp: currentTime, consumption: monthlyAverage });
			if (thisYearConsumption.length > 12) {
				thisYearConsumption.shift();
			}
		}
	}

  function calculateDailyAverage(): number {
		const sum = todayConsumption.reduce((acc, stat) => acc + stat.consumption, 0);
		return sum / todayConsumption.length;
	}

	function calculateMonthlyAverage(): number {
		const sum = thisMonthConsumption.reduce((acc, stat) => acc + stat.consumption, 0);
		return sum / thisMonthConsumption.length;
	}

	// Tick rate will be 1 second
	setInterval(updateConsumptionData, 1000);

	function calculateAverageConsumption(timeframe: string): number {
		let relevantStats: ConsumptionStat[] = [];
		switch (timeframe) {
			case 'This Hour':
				relevantStats = thisHourConsumption;
				break;
			case 'Today':
				relevantStats = todayConsumption;
				break;
			case 'This Month':
				relevantStats = thisMonthConsumption;
				break;
			case 'This Year':
				relevantStats = thisYearConsumption;
				break;
		}
		const totalConsumption = relevantStats.reduce((acc, stat) => acc + stat.consumption, 0);
		return relevantStats.length ? totalConsumption / relevantStats.length : 0;
	}

	onMount(() => {
		mounted = true;
		updateChart();
                socket = new WebSocket('ws://localhost:8080/sv');

		socket.onopen = () => {
			// Energy consumed map 0 -> 0 to a max of 1000 when reached in this hour consumtion a total of 1 k/wh
			
			setInterval(() => {
				const latestThisHour = thisHourConsumption[thisHourConsumption.length - 1];
				// console.log(latestThisHour);
				// console.log(thisHourConsumption)
				if (!latestThisHour || !socket) return;
				let energy = latestThisHour.consumption * 100;
				console.log("Sending energy event with value: " + energy);
				console.log(socket)
				socket.send("e: " + energy);
			}, 100);
		}
		socket.onerror = (event: Event) => {
			// console.log("WebSocket error:", event);	
		};
	});
</script>

<div class="devices mt-3">
	{#each devices as device}
		<button on:click={() => addDevice(device)} class="device device-button"
			><i class="fa-solid fa-{device.icon}"></i></button
		>
	{/each}
</div>
<div class="container" style="height: 80vh">
	<div
		class="row d-flex justify-content-between align-items-center position-relative"
		style="height: 100%"
	>
		<div id="house" class="ui-elem col-lg-5 col-12">
			{#each currentDevices as device}
				<DeviceComponent {device} />
			{/each}
		</div>
		<div class="connection-line d-none d-lg-block">
			{#if totalKwBeingConsumed > 0}
				<div class="energy-ball" style="animation-duration: 1s;"></div>
			{/if}
		</div>
		<div id="app" class="ui-elem col-lg-5 col-12">
			<div class="power-consumption">
				<h2>Smart House</h2>

				<div class="time-selector">
					<button
						class="time-button {selectedTimeframe === 'This Hour' ? 'active' : ''}"
						on:click={() => setTimeframe('This Hour')}>Hourly</button
					>
					<button
						class="time-button {selectedTimeframe === 'Today' ? 'active' : ''}"
						on:click={() => setTimeframe('Today')}>Daily</button
					>
					<button
						class="time-button {selectedTimeframe === 'This Month' ? 'active' : ''}"
						on:click={() => setTimeframe('This Month')}>Monthly</button
					>
					<button
						class="time-button {selectedTimeframe === 'This Year' ? 'active' : ''}"
						on:click={() => setTimeframe('This Year')}>Yearly</button
					>
				</div>

				<canvas id="consumptionChart"></canvas>
			</div>
		</div>
	</div>
</div>

<style>
	/* Add a pretty border to ui elements rounded in all sides white */
	.ui-elem {
		border: 3px solid white;
		border-radius: 10px;
		/* Height should be 100% of the parent */
		height: 100%;
	}

	.connection-line {
		position: absolute;
		top: 50%;
		left: 50%;
		transform: translate(-50%, -50%);
		width: 10%; /* Further reduced width */
		height: 3px;
		background-color: white;
		border-radius: 3px;
	}

	.energy-ball {
		position: absolute;
		width: 10px;
		height: 10px;
		background-color: white;
		border-radius: 50%;
		top: 50%; /* Center vertically */
		transform: translateY(-50%); /* Center vertically */
		animation: moveBall linear infinite alternate;
	}

	@keyframes moveBall {
		0% {
			left: 0;
		}
		100% {
			left: calc(100% - 10px);
		}
	}

	/* Hide on smaller devices */
	@media (max-width: 991.98px) {
		.connection-line {
			display: none;
		}
	}

	.devices {
		display: flex;
		justify-content: center;
		gap: 1rem;
		margin-bottom: 1rem;
	}

	.device-button {
		background-color: #3498db;
		color: white;
		border: none;
		border-radius: 50%;
		width: 60px;
		height: 60px;
		font-size: 1.5rem;
		cursor: pointer;
		transition: all 0.3s ease;
		box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
	}

	.device-button:hover {
		background-color: #2980b9;
		transform: translateY(-2px);
		box-shadow: 0 6px 8px rgba(0, 0, 0, 0.15);
	}

	.device-button:active {
		transform: translateY(0);
		box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
	}

	.power-consumption {
		padding: 1rem;
		color: white;
	}

	.time-selector {
		display: flex;
		justify-content: space-between;
		margin-bottom: 1rem;
	}

	.time-button {
		background-color: transparent;
		border: none;
		color: white;
		padding: 0.5rem 1rem;
		cursor: pointer;
		border-radius: 20px;
		transition: background-color 0.3s;
	}

	.time-button.active {
		background-color: rgba(255, 255, 255, 0.2);
	}

	.stat {
		font-size: 2.5rem;
		margin-bottom: 1rem;
		text-align: center;
	}

	.stat-value {
		font-weight: bold;
	}

	.stat-unit {
		font-size: 1.5rem;
		margin-left: 0.5rem;
	}

	.timeframe-picker {
		margin-top: 1rem;
	}

	.timeframe-picker select {
		width: 100%;
		padding: 0.5rem;
		border-radius: 8px;
		background-color: rgba(255, 255, 255, 0.1);
		color: white;
		border: none;
	}

	.power-consumption {
		padding: 1rem;
		color: white;
	}

	.total-consumption {
		font-size: 2.5rem;
		margin-bottom: 1rem;
	}

	.consumption-value {
		font-weight: bold;
	}

	.consumption-unit {
		font-size: 1.5rem;
		margin-left: 0.5rem;
	}

	.device-breakdown {
		display: flex;
		flex-direction: column;
		gap: 0.5rem;
	}

	.device-item {
		display: flex;
		align-items: center;
		background-color: rgba(255, 255, 255, 0.1);
		padding: 0.5rem;
		border-radius: 8px;
	}

	.device-item i {
		margin-right: 0.5rem;
		font-size: 1.2rem;
	}

	.device-name {
		flex-grow: 1;
	}

	.device-consumption {
		font-weight: bold;
	}
</style>
