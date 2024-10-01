<script lang="ts">
  import { onMount } from 'svelte';
  import type { HomeDevice } from '$lib/types/HomeDevice';

  export let device: HomeDevice;

  let draggableElement: HTMLElement;
  let isDragging = false;
  let startX: number, startY: number;
  let offsetX: number, offsetY: number;
  let dragStartTime: number;
  let hasMoved = false;

  onMount(() => {
    if (draggableElement) {
      draggableElement.addEventListener('mousedown', dragStart);
      draggableElement.addEventListener('touchstart', dragStart);
      window.addEventListener('mousemove', drag);
      window.addEventListener('touchmove', drag);
      window.addEventListener('mouseup', dragEnd);
      window.addEventListener('touchend', dragEnd);
    }
  });

  function dragStart(e: MouseEvent | TouchEvent) {
    isDragging = true;
    hasMoved = false;
    dragStartTime = Date.now();
    const event = 'touches' in e ? e.touches[0] : e;
    startX = event.clientX;
    startY = event.clientY;
    offsetX = draggableElement.offsetLeft;
    offsetY = draggableElement.offsetTop;
    draggableElement.style.cursor = 'grabbing';
  }

  function drag(e: MouseEvent | TouchEvent) {
    if (!isDragging) return;
    e.preventDefault();
    const event = 'touches' in e ? e.touches[0] : e;
    const dx = event.clientX - startX;
    const dy = event.clientY - startY;
    if (Math.abs(dx) > 5 || Math.abs(dy) > 5) {
      hasMoved = true;
    }
    draggableElement.style.left = `${offsetX + dx}px`;
    draggableElement.style.top = `${offsetY + dy}px`;
  }

  function dragEnd(e: MouseEvent | TouchEvent) {
    isDragging = false;
    if (!draggableElement) return;
    draggableElement.style.cursor = 'grab';
    if (!hasMoved && Date.now() - dragStartTime < 200) {
      toggleDevice();
    }

    const house = document.getElementById('house')!;
    const houseRect = house.getBoundingClientRect();
    const elementRect = draggableElement.getBoundingClientRect();

    if (
      elementRect.left < houseRect.left ||
      elementRect.top < houseRect.top ||
      elementRect.right > houseRect.right ||
      elementRect.bottom > houseRect.bottom
    ) {
      // Reset position if outside house bounds
      draggableElement.style.left = `${offsetX}px`;
      draggableElement.style.top = `${offsetY}px`;
    }
  }

  function toggleDevice() {
    device.isOn = !device.isOn;
  }

  function handleTouchEnd(event: TouchEvent) {
    if (!isDragging) {
      toggleDevice();
    }
    event.preventDefault();
  }

  $: backgroundColor = device.isOn ? 'white' : 'transparent';
  $: iconColor = device.isOn ? 'black' : 'white';
</script>

<div
  class="device"
  bind:this={draggableElement}
  on:mousedown={dragStart}
  on:touchend={handleTouchEnd}
  on:keydown={(e) => e.key === 'Enter' && toggleDevice()}
  role="button"
  tabindex="0"
  style="background-color: {backgroundColor};"
>
  <i class="fa-solid fa-{device.icon}" style="color: {iconColor};"></i>
</div>

<style>
  .device {
    border: 2px solid white;
    border-radius: 50%;
    width: 100px;
    height: 100px;
    display: flex;
    justify-content: center;
    align-items: center;
    position: absolute;
    cursor: grab;
    user-select: none;
    touch-action: none;
    transition: background-color 0.3s ease;
  }
  .device i {
    font-size: 24px;
    transition: color 0.3s ease;
  }
</style>